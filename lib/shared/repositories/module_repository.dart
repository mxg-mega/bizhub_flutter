import '../../core/services/firestore_service.dart';
import '../models/module_model.dart';

class ModuleRepository {
  static const String collectionPath = 'modules';

  static Future<ModuleModel?> getById(String id) async {
    return FirestoreService.getById<ModuleModel>(
      collectionPath: collectionPath,
      id: id,
      fromJson: ModuleModel.fromJson,
    );
  }

  static Future<void> upsert(ModuleModel module) async {
    await FirestoreService.setById<ModuleModel>(
      collectionPath: collectionPath,
      id: module.id,
      value: module,
      toJson: (m) => m.toJson(),
      merge: true,
    );
  }

  static Future<List<ModuleModel>> allEnabled() async {
    return FirestoreService.query<ModuleModel>(
      collectionPath: collectionPath,
      fromJson: ModuleModel.fromJson,
      where: [(q) => q.where('isEnabled', isEqualTo: true)],
      orderBy: const [OrderBy('name')],
    );
  }
}
