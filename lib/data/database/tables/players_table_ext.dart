import '../app_database.dart';
import '../../../domain/enums/class_type.dart';

extension PlayersTableDataX on PlayersTableData {
  ClassType? get classTypeEnum {
    final raw = classType;
    if (raw == null || raw.isEmpty) return null;
    return ClassType.values.asNameMap()[raw];
  }

  bool get isVitalist => classTypeEnum?.hasVitalism ?? false;
}
