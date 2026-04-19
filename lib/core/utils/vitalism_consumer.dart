class VitalismConsumeResult {
  final int newVitalism;
  final int newHp;
  const VitalismConsumeResult({required this.newVitalism, required this.newHp});
}

VitalismConsumeResult consumeSkillCost({
  required int currentVitalism,
  required int currentHp,
  required int cost,
}) {
  if (currentVitalism >= cost) {
    return VitalismConsumeResult(
      newVitalism: currentVitalism - cost,
      newHp: currentHp,
    );
  }
  final deficit = cost - currentVitalism;
  final hpCost = (deficit * 0.99).round();
  return VitalismConsumeResult(
    newVitalism: 0,
    newHp: (currentHp - hpCost).clamp(0, currentHp),
  );
}
