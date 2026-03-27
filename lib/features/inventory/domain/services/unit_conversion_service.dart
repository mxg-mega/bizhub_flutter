import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/unit_chain_model.dart';

part 'unit_conversion_service.g.dart';

@riverpod
UnitConversionService unitConversionService(final UnitConversionServiceRef ref) {
  return UnitConversionService();
}

class UnitConversionService {
  /// Calculates the conversion factor from [fromUnit] to [toUnit] using BFS.
  /// 
  /// For example, if 1 Carton = 6 Boxes and 1 Box = 12 Pieces:
  /// - calculateFactor(chain, 'Carton', 'Piece') -> 72.0
  /// - calculateFactor(chain, 'Piece', 'Carton') -> 0.01388... (1/72)
  double calculateFactor(
    final UnitChainModel chain,
    final String fromUnit,
    final String toUnit,
  ) {
    if (fromUnit == toUnit) return 1.0;

    // Build Adjacency List (Graph)
    final Map<String, List<_UnitEdge>> graph = {};

    final conversions = chain.conversions;
    if (conversions != null) {
      for (final conv in conversions) {
        // Forward direction
        graph.putIfAbsent(conv.from, () => []).add(_UnitEdge(conv.to, conv.factor));
        
        // Backward direction
        if (conv.bidirectional) {
          graph.putIfAbsent(conv.to, () => []).add(_UnitEdge(conv.from, conv.reverseFactor));
        }
      }
    }

    // BFS Queue: Stores {currentUnit, cumulativeFactor}
    final List<_BFSNode> queue = [_BFSNode(fromUnit, 1.0)];
    final Set<String> visited = {fromUnit};

    int head = 0;
    while (head < queue.length) {
      final current = queue[head++];
      
      if (current.unit == toUnit) {
        return current.factor;
      }

      final neighbors = graph[current.unit] ?? [];
      for (final edge in neighbors) {
        if (!visited.contains(edge.to)) {
          visited.add(edge.to);
          queue.add(_BFSNode(edge.to, current.factor * edge.multiplier));
        }
      }
    }

    throw Exception('No conversion path found from $fromUnit to $toUnit in chain ${chain.id}');
  }
}

class _UnitEdge {
  final String to;
  final double multiplier;
  _UnitEdge(this.to, this.multiplier);
}

class _BFSNode {
  final String unit;
  final double factor;
  _BFSNode(this.unit, this.factor);
}
