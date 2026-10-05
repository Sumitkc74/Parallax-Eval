// draft_service.dart
// Provides a simple in‑memory draft persistence for various screens.
// In a full app this could be backed by SharedPreferences or Hive, but for
// the purposes of the current UI guards we only need a singleton with getters
// and setters that survive while the app is running.

import 'package:flutter/material.dart';

class DraftService {
  // Singleton pattern
  DraftService._();
  static final DraftService instance = DraftService._();

  // Draft fields – nullable strings that store the latest user input.
  String? inspectorPromptDraft;
  String? redTeamSeedDraft;
  Map<String, dynamic>? experimentDraft;
  Map<String, dynamic>? customPromptDraft;

  /// Saves a draft for the experiment creation dialog.
  void saveExperimentDraft(Map<String, dynamic> data) {
    experimentDraft = Map<String, dynamic>.from(data);
  }

  /// Clears the stored experiment draft.
  void clearExperimentDraft() {
    experimentDraft = null;
  }

  /// Saves a draft for the custom prompt pair dialog.
  void saveCustomPromptDraft(Map<String, dynamic> data) {
    customPromptDraft = Map<String, dynamic>.from(data);
  }

  /// Clears the stored custom prompt draft.
  void clearCustomPromptDraft() {
    customPromptDraft = null;
  }

  /// Shows a modal asking the user whether to discard unsaved changes.
  /// Returns `true` if the user confirms discarding, `false` otherwise.
  static Future<bool> confirmDiscard(BuildContext context, {required String formName}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: Text('You have unsaved changes in "$formName". Discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A2C2C), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result == true;
  }
}

