class EstimateBusStop {
  final int direction;
  final int? estimateTime;
  final String stopNamesZh;

  const EstimateBusStop({
    required this.direction,
    required this.estimateTime,
    required this.stopNamesZh,
  });

  factory EstimateBusStop.fromJson(Map<String, dynamic> json) {
    return EstimateBusStop(
      direction: json['Direction'],
      estimateTime: json['EstimateTime'],
      stopNamesZh: json['StopName']['Zh_tw'],
    );
  }
}
