# Copyright 2019, The TensorFlow Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Implements DPQuery interface for adaptive clip queries.

Instead of a fixed clipping norm specified in advance, the clipping norm is
dynamically adjusted to match a target fraction of clipped updates per sample,
where the actual fraction of clipped updates is itself estimated in a
differentially private manner. For details see Thakkar et al., "Differentially
Private Learning with Adaptive Clipping" [http://arxiv.org/abs/1905.03871].
"""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import collections

import tensorflow.compat.v1 as tf

from tensorflow_privacy.privacy.dp_query import dp_query
from tensorflow_privacy.privacy.dp_query import gaussian_query
from tensorflow_privacy.privacy.dp_query import normalized_query


class QuantileAdaptiveClipSumQuery(dp_query.SumAggregationDPQuery):
  """DPQuery for sum queries with adaptive clipping.

  Clipping norm is tuned adaptively to converge to a value such that a specified
  quantile of updates are clipped.
  """

  # pylint: disable=invalid-name
  _GlobalState = collections.namedtuple(
      '_GlobalState', [
          'noise_multiplier',
          'target_unclipped_quantile',
          'learning_rate',
          'sum_state',
          'clipped_fraction_state'])

  # pylint: disable=invalid-name
  _SampleState = collections.namedtuple(
      '_SampleState', ['sum_state', 'clipped_fraction_state'])

  # pylint: disable=invalid-name
  _SampleParams = collections.namedtuple(
      '_SampleParams', ['sum_params', 'clipped_fraction_params'])

  def __init__(
      self,
      initial_l2_norm_clip,
      noise_multiplier,
      target_unclipped_quantile,
      learning_rate,
      clipped_count_stddev,
      expected_num_records,
      geometric_update=False):
    """Initializes the QuantileAdaptiveClipSumQuery.

    Args:
      initial_l2_norm_clip: The initial value of clipping norm.
      noise_multiplier: The multiplier of the l2_norm_clip to make the stddev of
        the noise added to the output of the sum query.
      target_unclipped_quantile: The desired quantile of updates which should be
        unclipped. I.e., a value of 0.8 means a value of l2_norm_clip should be
        found for which approximately 20% of updates are clipped each round.
      learning_rate: The learning rate for the clipping norm adaptation. A
        rate of r means that the clipping norm will change by a maximum of r at
        each step. This maximum is attained when |clip - target| is 1.0.
      clipped_count_stddev: The stddev of the noise added to the clipped_count.
        Since the sensitivity of the clipped count is 0.5, as a rule of thumb it
        should be about 0.5 for reasonable privacy.
      expected_num_records: The expected number of records per round, used to
        estimate the clipped count quantile.
      geometric_update: If True, use geometric updating of clip.
    """
    self._initial_l2_norm_clip = initial_l2_norm_clip
    self._noise_multiplier = noise_multiplier
    self._target_unclipped_quantile = target_unclipped_quantile
    self._learning_rate = learning_rate

    # Initialize sum query's global state with None, to be set later.
    self._sum_query = gaussian_query.GaussianSumQuery(None, None)

    # self._clipped_fraction_query is a DPQuery used to estimate the fraction of
    # records that are clipped. It accumulates an indicator 0/1 of whether each
    # record is clipped, and normalizes by the expected number of records. In
    # practice, we accumulate clipped counts shifted by -0.5 so they are
    # centered at zero. This makes the sensitivity of the clipped count query
    # 0.5 instead of 1.0, since the maximum that a single record could affect
    # the count is 0.5. Note that although the l2_norm_clip of the clipped
    # fraction query is 0.5, no clipping will ever actually occur because the
    # value of each record is always +/-0.5.
    self._clipped_fraction_query = gaussian_query.GaussianAverageQuery(
        l2_norm_clip=0.5,
        sum_stddev=clipped_count_stddev,
        denominator=expected_num_records)

    self._geometric_update = geometric_update

  def set_ledger(self, ledger):
    """See base class."""
    self._sum_query.set_ledger(ledger)
    self._clipped_fraction_query.set_ledger(ledger)

  def initial_global_state(self):
    """See base class."""
    initial_l2_norm_clip = tf.cast(self._initial_l2_norm_clip, tf.float32)
    noise_multiplier = tf.cast(self._noise_multiplier, tf.float32)
    target_unclipped_quantile = tf.cast(self._target_unclipped_quantile,
                                        tf.float32)
    learning_rate = tf.cast(self._learning_rate, tf.float32)
    sum_stddev = initial_l2_norm_clip * noise_multiplier

    sum_query_global_state = self._sum_query.make_global_state(
        l2_norm_clip=initial_l2_norm_clip,
        stddev=sum_stddev)

    return self._GlobalState(
        noise_multiplier,
        target_unclipped_quantile,
        learning_rate,
        sum_query_global_state,
        self._clipped_fraction_query.initial_global_state())

  def derive_sample_params(self, global_state):
    """See base class."""

    # Assign values to variables that inner sum query uses.
    sum_params = self._sum_query.derive_sample_params(global_state.sum_state)
    clipped_fraction_params = self._clipped_fraction_query.derive_sample_params(
        global_state.clipped_fraction_state)
    return self._SampleParams(sum_params, clipped_fraction_params)

  def initial_sample_state(self, template):
    """See base class."""
    sum_state = self._sum_query.initial_sample_state(template)
    clipped_fraction_state = self._clipped_fraction_query.initial_sample_state(
        tf.constant(0.0))
    return self._SampleState(sum_state, clipped_fraction_state)

  def preprocess_record(self, params, record):
    preprocessed_sum_record, global_norm = (
        self._sum_query.preprocess_record_impl(params.sum_params, record))

    # Note we are relying on the internals of GaussianSumQuery here. If we want
    # to open this up to other kinds of inner queries we'd have to do this in a
    # more general way.
    l2_norm_clip = params.sum_params

    # We accumulate clipped counts shifted by 0.5 so they are centered at zero.
    # This makes the sensitivity of the clipped count query 0.5 instead of 1.0.
    was_clipped = tf.cast(global_norm >= l2_norm_clip, tf.float32) - 0.5

    return self._SampleState(preprocessed_sum_record, was_clipped)

  def get_noised_result(self, sample_state, global_state):
    """See base class."""
    gs = global_state

    noised_vectors, sum_state = self._sum_query.get_noised_result(
        sample_state.sum_state, gs.sum_state)
    del sum_state  # Unused. To be set explicitly later.

    clipped_fraction_result, new_clipped_fraction_state = (
        self._clipped_fraction_query.get_noised_result(
            sample_state.clipped_fraction_state,
            gs.clipped_fraction_state))

    # Unshift clipped percentile by 0.5. (See comment in initializer.)
    clipped_quantile = clipped_fraction_result + 0.5
    unclipped_quantile = 1.0 - clipped_quantile

    # Protect against out-of-range estimates.
    unclipped_quantile = tf.minimum(1.0, tf.maximum(0.0, unclipped_quantile))

    # Loss function is convex, with derivative in [-1, 1], and minimized when
    # the true quantile matches the target.
    loss_grad = unclipped_quantile - global_state.target_unclipped_quantile

    update = global_state.learning_rate * loss_grad

    if self._geometric_update:
      new_l2_norm_clip = gs.sum_state.l2_norm_clip * tf.math.exp(-update)
    else:
      new_l2_norm_clip = tf.math.maximum(0.0,
                                         gs.sum_state.l2_norm_clip - update)

    new_sum_stddev = new_l2_norm_clip * global_state.noise_multiplier
    new_sum_query_global_state = self._sum_query.make_global_state(
        l2_norm_clip=new_l2_norm_clip,
        stddev=new_sum_stddev)

    new_global_state = global_state._replace(
        sum_state=new_sum_query_global_state,
        clipped_fraction_state=new_clipped_fraction_state)

    return noised_vectors, new_global_state


class QuantileAdaptiveClipAverageQuery(normalized_query.NormalizedQuery):
  """DPQuery for average queries with adaptive clipping.

  Clipping norm is tuned adaptively to converge to a value such that a specified
  quantile of updates are clipped.

  Note that we use "fixed-denominator" estimation: the denominator should be
  specified as the expected number of records per sample. Accumulating the
  denominator separately would also be possible but would be produce a higher
  variance estimator.
  """

  def __init__(
      self,
      initial_l2_norm_clip,
      noise_multiplier,
      denominator,
      target_unclipped_quantile,
      learning_rate,
      clipped_count_stddev,
      expected_num_records,
      geometric_update=False):
    """Initializes the AdaptiveClipAverageQuery.

    Args:
      initial_l2_norm_clip: The initial value of clipping norm.
      noise_multiplier: The multiplier of the l2_norm_clip to make the stddev of
        the noise.
      denominator: The normalization constant (applied after noise is added to
        the sum).
      target_unclipped_quantile: The desired quantile of updates which should be
        clipped.
      learning_rate: The learning rate for the clipping norm adaptation. A
        rate of r means that the clipping norm will change by a maximum of r at
        each step. The maximum is attained when |clip - target| is 1.0.
      clipped_count_stddev: The stddev of the noise added to the clipped_count.
        Since the sensitivity of the clipped count is 0.5, as a rule of thumb it
        should be about 0.5 for reasonable privacy.
      expected_num_records: The expected number of records, used to estimate the
        clipped count quantile.
      geometric_update: If True, use geometric updating of clip.
    """
    numerator_query = QuantileAdaptiveClipSumQuery(
        initial_l2_norm_clip,
        noise_multiplier,
        target_unclipped_quantile,
        learning_rate,
        clipped_count_stddev,
        expected_num_records,
        geometric_update)
    super(QuantileAdaptiveClipAverageQuery, self).__init__(
        numerator_query=numerator_query,
        denominator=denominator)
