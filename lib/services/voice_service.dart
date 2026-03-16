import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/product_model.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  bool get isListening => _speech.isListening;

  Future<bool> startListening(ValueChanged<String> onTextChanged) async {
    final available = await _speech.initialize();
    if (!available) {
      return false;
    }

    await _speech.listen(
      onResult: (result) => onTextChanged(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Map<String, int> parseOrderText(String input, List<Product> products) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return {};
    }

    // Build alias map from product names
    final aliases = <String, String>{};
    for (final product in products) {
      aliases[product.name.toLowerCase()] = product.name;
      // Also add every individual word of multi-word product names
      for (final word in product.name.toLowerCase().split(RegExp(r'\s+'))) {
        if (word.length >= 3) {
          aliases.putIfAbsent(word, () => product.name);
        }
      }
    }

    // Common misspellings / aliases
    const manualAliases = {
      'tee': 'Tea',
      'cofee': 'Coffee',
      'parota': 'Porota',
      'parotta': 'Porota',
      'porotta': 'Porota',
      'baroto': 'Porota',
      'barotta': 'Porota',
      'prota': 'Porota',
      'omelet': 'Omelette',
      'omlet': 'Omelette',
      'dosai': 'Dosa',
      'tosa': 'Dosa',
      'idaly': 'Idly',
      'idli': 'Idly',
      'briyani': 'Biryani',
      'beryani': 'Biryani',
      'bryani': 'Biryani',
    };

    for (final entry in manualAliases.entries) {
      if (products.any((p) => p.name == entry.value)) {
        aliases[entry.key] = entry.value;
      }
    }

    final numberWords = <String, int>{
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
    };

    final tokens = normalized.split(' ');
    final parsed = <String, int>{};

    int index = 0;
    while (index < tokens.length) {
      final quantity = int.tryParse(tokens[index]) ?? numberWords[tokens[index]];

      if (quantity != null && index + 1 < tokens.length) {
        // Try multi-word product names (e.g., "milk packets")
        String? canonical;
        for (int wordLen = 3; wordLen >= 1; wordLen--) {
          if (index + 1 + wordLen > tokens.length) continue;
          final candidateName =
              tokens.sublist(index + 1, index + 1 + wordLen).join(' ');
          canonical = aliases[candidateName];
          canonical ??= _fuzzyLookup(candidateName, products);
          if (canonical != null) {
            parsed.update(canonical, (v) => v + quantity,
                ifAbsent: () => quantity);
            index += 1 + wordLen;
            break;
          }
        }
        if (canonical != null) continue;
      }

      // Exact/alias lookup for single token
      String? canonical = aliases[tokens[index]];
      // Fuzzy fallback when no exact match found
      canonical ??= _fuzzyLookup(tokens[index], products);
      if (canonical != null) {
        parsed.update(canonical, (v) => v + 1, ifAbsent: () => 1);
      }
      index += 1;
    }

    return parsed;
  }

  /// Returns the product name whose name (or any of its individual words) is
  /// within Levenshtein distance 2 of [token].  Returns null if nothing close
  /// enough is found.
  String? _fuzzyLookup(String token, List<Product> products) {
    if (token.length < 3) return null;
    String? best;
    int bestDist = 3; // threshold (exclusive)

    for (final product in products) {
      final nameLower = product.name.toLowerCase();

      // Check distance against full product name
      final fullDist = _levenshtein(token, nameLower);
      if (fullDist < bestDist) {
        bestDist = fullDist;
        best = product.name;
      }

      // Also check each word in the product name
      for (final word in nameLower.split(RegExp(r'\s+'))) {
        if (word.length < 3) continue;
        // Substring containment check (fast shortcut)
        if (word.contains(token) || token.contains(word)) {
          return product.name;
        }
        final d = _levenshtein(token, word);
        if (d < bestDist) {
          bestDist = d;
          best = product.name;
        }
      }
    }

    return best;
  }

  /// Classic iterative Levenshtein distance.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Keep only two rows to save memory
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }
}