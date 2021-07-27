class Prediction {
  String placeId;
  String mainText;
  String secondaryText;
  Prediction({
    this.placeId,
    this.mainText,
    this.secondaryText,
  });
  Prediction.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("id") &&
        json.containsKey("title") &&
        json.containsKey("address") &&
        json["address"].containsKey("label")) {
      placeId = json["id"];
      mainText = json["title"];
      secondaryText = json["address"]["label"];
    }
  }
}
