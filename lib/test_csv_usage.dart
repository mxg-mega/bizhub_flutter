import 'package:csv/csv.dart';

void main() {
  final rows = [
    ['a', 'b'],
    ['c', 'd'],
  ];
  final csvString = csv.encode(rows);
  print(csvString);
  final stringCsv = csv.decode(csvString);
  print(stringCsv);
}
