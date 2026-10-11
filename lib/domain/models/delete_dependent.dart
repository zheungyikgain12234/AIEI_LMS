/// One record that still points at something being deleted, and what the
/// admin may do with it: move it to one of [targets], or (when [noneLabel]
/// is set) apply the "none" action — delete it, unassign it, clear the field.
class DeleteDependent {
  const DeleteDependent({
    required this.kind,
    required this.kindPlural,
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.targets,
    this.noneLabel,
    this.noneVerb = 'deleted',
  });

  /// Groups dependents of the same type; passed back in [DeleteDecision].
  final String kind;
  final String kindPlural;
  final String id;
  final String title;
  final String subtitle;

  /// (id, label) pairs this record can be moved to.
  final List<(String, String)> targets;

  /// Label of the "no reassignment" choice, e.g. "Delete this award".
  final String? noneLabel;

  /// Past-tense verb used in the summary for records given the none action.
  final String noneVerb;
}

/// The admin's choice for one [DeleteDependent]. [targetId] is null for the
/// none action.
class DeleteDecision {
  const DeleteDecision(this.kind, this.id, this.targetId);
  final String kind;
  final String id;
  final String? targetId;
}
