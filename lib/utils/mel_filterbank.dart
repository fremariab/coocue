// lib/utils/mel_filterbank.dart
import 'dart:math';

class MelFilterbank {
  final int numMel;
  final int fftBins;
  final List<List<double>> _filters;

  MelFilterbank(this.numMel, int fftSize, int sampleRate)
      : fftBins = fftSize ~/ 2,
        _filters = [] {
    final melMin = _hzToMel(0);
    final melMax = _hzToMel(sampleRate / 2);
    final melPoints = List<double>.generate(
      numMel + 2,
      (i) => melMin + (melMax - melMin) * i / (numMel + 1),
    );
    final hzPoints = melPoints.map(_melToHz).toList();
    final binPoints = hzPoints
        .map((hz) => ((fftSize + 1) * hz / sampleRate).floor())
        .toList();

    for (var m = 0; m < numMel; m++) {
      final start = binPoints[m];
      final center = binPoints[m + 1];
      final end = binPoints[m + 2];
      final filter = List<double>.filled(fftBins, 0.0);
      for (var k = start; k < center && k < fftBins; k++) {
        filter[k] = (k - start) / (center - start);
      }
      for (var k = center; k < end && k < fftBins; k++) {
        filter[k] = (end - k) / (end - center);
      }
      _filters.add(filter);
    }
  }

  List<double> apply(List<double> powerSpectrum) {
    final melEnergies = <double>[];
    for (var m = 0; m < numMel; m++) {
      var sum = 0.0, wsum = 0.0;
      for (var k = 0; k < fftBins; k++) {
        final w = _filters[m][k];
        sum += w * powerSpectrum[k];
        wsum += w;
      }
      final val = wsum > 0 ? sum / wsum : 0.0;
      // Convert to dB like librosa
      melEnergies.add(10 * log(max(val, 1e-10)) / ln10);
    }
    return melEnergies;
  }

  static double _hzToMel(double hz) => 2595 * log(1 + hz / 700) / ln10;
  static double _melToHz(double mel) => 700 * (pow(10, mel / 2595) - 1);
}
