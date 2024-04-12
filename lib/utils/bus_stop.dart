class BusStop {
  final int direction;
  final List<String> stopNamesZh;

  const BusStop({
    required this.direction,
    required this.stopNamesZh,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    int direction = json['Direction'];
    List<dynamic> stopsData = json['Stops'];
    List<String> stopNamesZh = stopsData
        .map<String>((stop) => stop['StopName']['Zh_tw'] as String)
        .toList();

    return BusStop(
      direction: direction,
      stopNamesZh: stopNamesZh,
    );
  }
}
