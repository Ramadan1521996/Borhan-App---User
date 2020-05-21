
import 'dart:convert';
import 'package:Borhan_User/models/campaign.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CampaignNotifier with ChangeNotifier {
  List <Campaign> _campaignList =[];
  Campaign _currentCampaign;

  Campaign get currentCampaign => _currentCampaign;

  set currentCampaign (Campaign campaign) {
    _currentCampaign = campaign;
    notifyListeners();
  }

  List<Campaign> get campaignList {
    return [..._campaignList];
  }

  Future<void> fetchAndSetProducts() async {
    const url = 'https://borhanadmin.firebaseio.com/Campaigns.json';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
     // print((response.body));
      final List<Campaign> loadedCampaigns = [];
      extractedData.forEach((prodId, prodData) {
        loadedCampaigns.add(Campaign(
          id: prodId,
          campaignName: prodData['name'],
          campaignDescription: prodData['description'],
          imagesUrl: prodData['image'],
          time: prodData['time'],
        ));
      });
      _campaignList = loadedCampaigns;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }


}