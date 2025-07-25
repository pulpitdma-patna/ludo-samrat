class GameResult {
  final int playerId;
  final int rank;
  final String? name;

  GameResult({required this.playerId, required this.rank, this.name});

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      playerId: map['player_id'] as int? ?? map['player'] as int,
      rank: map['rank'] as int? ?? 0,
      name: map['name'] as String?,
    );
  }
}
