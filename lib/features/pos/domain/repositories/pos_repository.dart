import '../../data/models/sale_model.dart';


abstract class PosRepository {
  Stream<List<SaleModel>> watchSales(final String businessId);
  Future<void> saveSale(final SaleModel sale);
  Future<List<SaleModel>> getSales(final String businessId);
}
