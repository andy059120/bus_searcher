enum BusCity {
  taipei('Taipei', '臺北市'),
  newTaipei('NewTaipei', '新北市');

  const BusCity(this.apiName, this.label);

  final String apiName;
  final String label;
}
