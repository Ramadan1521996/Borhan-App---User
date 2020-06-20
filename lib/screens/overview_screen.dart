import 'dart:async';
import 'dart:io';
import 'package:translator/translator.dart';
import 'package:Borhan_User/Animation/FadeAnimation.dart';
import 'package:Borhan_User/models/user_nav.dart';
import 'package:Borhan_User/notifiers/campaign_notifier.dart';
import 'package:Borhan_User/notifiers/organization_notifier.dart';
import 'package:Borhan_User/providers/shard_pref.dart';
import 'package:Borhan_User/screens/campaign_details.dart';
import 'package:Borhan_User/screens/fast_donation.dart';
import 'package:Borhan_User/screens/navigation_drawer.dart';
import 'package:Borhan_User/screens/org_widgets/movie_details_page.dart';
import 'package:Borhan_User/screens/organization_activities.dart';
import 'package:app_settings/app_settings.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity/connectivity.dart';
import '../app_localizations.dart';
import '../background.dart';
import 'package:devicelocale/devicelocale.dart';

class OrgOverviewScreen extends StatefulWidget {
  static const routeName = '/home';
  var translated;
  @override
  _OrgOverviewScreenState createState() => _OrgOverviewScreenState();
}

class _OrgOverviewScreenState extends State<OrgOverviewScreen> {
  StreamSubscription connectivitySubscription;
  ConnectivityResult _previousResult;
  bool dialogShown = false;
  List _languages = List();

  set translated(String translated) {}
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('login_string')),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child:
                Text(AppLocalizations.of(context).translate('not_now_string')),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          FlatButton(
            child: Text(AppLocalizations.of(context).translate('yes_string')),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushNamed(context, '/Login');
            },
          ),
        ],
      ),
    );
  }

  Future<UserNav> loadSharedPrefs() async {
    UserNav user;
    try {
      SharedPref sharedPref = SharedPref();
      user = UserNav.fromJson(await sharedPref.read("user"));
    } catch (Excepetion) {
      // do something
    }
    return user;
  }

  Future<bool> checkinternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return Future.value(true);
      }
    } on SocketException catch (_) {
      return Future.value(false);
    }
  }

  Future<void> translateWords(String myWord) async {
    final translator = new GoogleTranslator();
    translated = await translator.translate(myWord, from: 'ar', to: 'en');
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();

    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult connresult) {
      if (connresult == ConnectivityResult.none) {
        dialogShown = true;
        showDialog(
            context: context,
            barrierDismissible: false,
            child: AlertDialog(
              title: Text(AppLocalizations.of(context)
                  .translate('Something_went_wrong_String')),
              content: Text(AppLocalizations.of(context).translate('internet')),
              actions: <Widget>[
                FlatButton(
                    onPressed: () => {
                          SystemChannels.platform
                              .invokeMethod('SystemNavigator.pop'),
                        },
                    child: Text(
                      AppLocalizations.of(context).translate('exit'),
                      style: TextStyle(color: Colors.red),
                    )),
                FlatButton(
                    onPressed: () => {
                          AppSettings.openWIFISettings(),
                        },
                    child: Text(
                      AppLocalizations.of(context).translate('wisettings'),
                      style: TextStyle(color: Colors.blue),
                    )),
                FlatButton(
                    onPressed: () => {
                          AppSettings.openDataRoamingSettings(),
                        },
                    child: Text(
                      AppLocalizations.of(context).translate('Sim'),
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ))
              ],
            ));
      } else if (_previousResult == ConnectivityResult.none) {
        checkinternet().then((result) {
          if (result == true) {
            if (dialogShown == true) {
              dialogShown = false;

              getOrganizationsAndCampaign();

              Navigator.pop(context);
            }
          }
        });
      }
      _previousResult = connresult;
    });
  }

  Future<void> initPlatformState() async {
    List languages;
    print("Hiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii");
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      languages = await Devicelocale.preferredLanguages;
      print(languages);
    } on PlatformException {
      print("Error obtaining preferred languages");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    print("Hi Language of Device" + languages[0].toString());
    setState(() {
      _languages = languages;
    });
  }

  @override
  void dispose() {
    super.dispose();
    connectivitySubscription.cancel();
  }

  var _isLoading = false;
  var _isInit = true;

  var campaignNotifier;
  var orgNotifier;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      campaignNotifier = Provider.of<CampaignNotifier>(context, listen: false);
      orgNotifier = Provider.of<OrganizationNotifier>(context, listen: false);

      getOrganizationsAndCampaign();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> getOrganizationsAndCampaign() async {
    setState(() {
      _isLoading = true;
    });

    await Provider.of<OrganizationNotifier>(context).getOrganizations();

    await Provider.of<CampaignNotifier>(context).fetchAndSetProducts();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;
    final translator = new GoogleTranslator();
//    print(_languages[0].toString());
    final headerList = new ListView.builder(
      itemBuilder: (context, index) {
        EdgeInsets padding = index == 0
            ? const EdgeInsets.only(
                left: 20.0, right: 10.0, top: 5.0, bottom: 15.0)
            : const EdgeInsets.only(
                left: 20.0, right: 10.0, top: 5.0, bottom: 15.0);

        return new Padding(
          padding: padding,
          child: new InkWell(
            onTap: () {
              campaignNotifier.currentCampaign =
                  campaignNotifier.campaignList[index];

              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return CampaignDetail();
              }));
            },
            child: FadeAnimation(
              1,
              Container(
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.circular(10.0),
                  color: Colors.purple[100],
                  boxShadow: [
                    new BoxShadow(
                        color: Colors.blueGrey.withAlpha(100),
                        offset: const Offset(3.0, 10.0),
                        blurRadius: 10.0)
                  ],
                  image: new DecorationImage(
                    image: new NetworkImage(
                        campaignNotifier.campaignList[index].imagesUrl),
                    fit: BoxFit.fill,
                  ),
                ),
                width: 150.0,
                child: new Stack(
                  children: <Widget>[
                    new Align(
                      alignment: Alignment.bottomCenter,
                      child: new Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        decoration: new BoxDecoration(
                            color: Colors.purple[300],
                            borderRadius: new BorderRadius.only(
                                bottomLeft: new Radius.circular(10.0),
                                bottomRight: new Radius.circular(10.0))),
                        height: 35.0,
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _languages[0].toString() == 'en_US'
                                ? Flexible(
                                    child: new Container(
                                      child: new Text(
                                        campaignNotifier
                                            .translatedCampaignList[index]
                                            .campaignName,
                                        overflow: TextOverflow.ellipsis,
                                        style: new TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  )
                                : Flexible(
                                    child: new Container(
                                      child: new Text(
                                        campaignNotifier
                                            .campaignList[index].campaignName,
                                        overflow: TextOverflow.ellipsis,
                                        style: new TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
      scrollDirection: Axis.horizontal,
      itemCount: campaignNotifier.campaignList.length,
    );

    final body = new Scaffold(
      appBar: new AppBar(
        title: new Text(
          AppLocalizations.of(context).translate("Burhan"),
          style: new TextStyle(
              color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple[900],
      ),
      drawer: NavigationDrawer(),
      backgroundColor: Colors.purple[50],
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Container(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Container(
                      height: 190.0,
                      child: new Carousel(
                        boxFit: BoxFit.cover,
                        images: [
                          AssetImage('assets/offers/Offer1.jpg'),
                          AssetImage('assets/offers/Offer2.jpg'),
                          AssetImage('assets/offers/Offer3.jpg'),
                          AssetImage('assets/offers/Offer4.jpg'),
                          AssetImage('assets/offers/Offer5.jpg'),
                        ],
                        autoplay: true,
                        animationCurve: Curves.fastLinearToSlowEaseIn,
                        animationDuration: Duration(milliseconds: 2000),
                        dotSize: 4.0,
                        indicatorBgPadding: 2.0,
                      ),
                    ),
                    campaignNotifier.campaignList.length != 0
                        ? new Container(
                            height: 150.0, width: _width, child: headerList)
                        : Container(
                            child: Text(AppLocalizations.of(context)
                                .translate('no_camp'))),
                    ButtonTheme(
                      minWidth: MediaQuery.of(context).size.width - 50,
                      height: 50.0,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            RaisedButton(
                              color: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(24.0),
                              ),
                              onPressed: () async {
                                UserNav userLoad = await loadSharedPrefs();
                                if (userLoad == null) {
                                  print("user is not here");
                                  _showErrorDialog(AppLocalizations.of(context)
                                      .translate('Please_signin_first_string'));
                                } else {
                                  print("user is  here");
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return FastDonationScreen();
                                      },
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate('Donate_Now_String'),
                                style: TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: orgNotifier.orgList.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: new BorderRadius.circular(20),
                          child: Card(
                            margin: EdgeInsets.fromLTRB(20, 5, 20, 5),
                            color: Colors.purple[200],
                            child: new ListTile(
                              contentPadding: EdgeInsets.fromLTRB(5, 5, 10, 0),
                              title: new Column(
                                children: <Widget>[
                                  new Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      FadeAnimation(
                                        2,
                                        Container(
                                          height: 100,
                                          width: 100,
                                          decoration: new BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              color: Colors.purple[300],
                                              boxShadow: [
                                                new BoxShadow(
                                                    color: Colors.blueGrey
                                                        .withAlpha(70),
                                                    offset:
                                                        const Offset(2.0, 2.0),
                                                    blurRadius: 2.0)
                                              ],
                                              image: new DecorationImage(
                                                image: orgNotifier
                                                                .orgList[index]
                                                                .logo !=
                                                            null &&
                                                        orgNotifier
                                                                .orgList[index]
                                                                .logo !=
                                                            ""
                                                    ? new NetworkImage(
                                                        orgNotifier
                                                            .orgList[index]
                                                            .logo)
                                                    : NetworkImage(
                                                        'https://img2.arabpng.com/20171128/5d2/gold-soccer-ball-png-clip-art-image-5a1d466b159ac0.0656563615118680110885.jpg'),
                                                fit: BoxFit.cover,
                                              )),
                                        ),
                                      ),
                                      new SizedBox(
                                        width: 10.0,
                                      ),
                                      new Expanded(
                                          child: new Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          FadeAnimation(
                                            1.3,
                                            Text(
                                              orgNotifier.orgList[index]
                                                          .orgName !=
                                                      null
                                                  ? (_languages[0].toString() ==
                                                          'en_US'
                                                      ? orgNotifier
                                                          .translatedOrgList[
                                                              index]
                                                          .orgName
                                                      : orgNotifier
                                                          .orgList[index]
                                                          .orgName)
                                                  : 'no value',
                                              style: new TextStyle(
                                                  fontSize: 18.0,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          FadeAnimation(
                                            1.3,
                                            Text(
                                              orgNotifier.orgList[index]
                                                          .description !=
                                                      null
                                                  ? (_languages[0].toString() ==
                                                          'en_US'
                                                      ? orgNotifier
                                                          .translatedOrgList[
                                                              index]
                                                          .description
                                                      : orgNotifier
                                                          .orgList[index]
                                                          .description)
                                                  : 'no value',
                                              style: new TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 10.0,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: <Widget>[
                                              RaisedButton(
                                                color: Colors.deepPurple[50],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      new BorderRadius.circular(
                                                          10.0),
                                                  side: BorderSide(
                                                      color: Colors.black),
                                                ),
                                                onPressed: () {
                                                  orgNotifier
                                                          .currentOrganization =
                                                      orgNotifier
                                                          .orgList[index];

                                                  Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        pageBuilder: (c, a1,
                                                                a2) =>
                                                            MovieDetailsPage(
                                                          orgNotifier
                                                              .orgList[index],
                                                        ),
                                                        transitionsBuilder: (c,
                                                                anim,
                                                                a2,
                                                                child) =>
                                                            FadeTransition(
                                                                opacity: anim,
                                                                child: child),
                                                        transitionDuration:
                                                            Duration(
                                                                milliseconds:
                                                                    500),
                                                      ));
                                                },
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'Details_String'),
                                                  style: TextStyle(
                                                      fontSize: 18.0,
                                                      color: Colors.black),
                                                ),
                                              ),
                                              RaisedButton(
                                                color: Colors.deepPurple[50],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      new BorderRadius.circular(
                                                          10.0),
                                                  side: BorderSide(
                                                      color: Colors.black),
                                                ),
                                                onPressed: () {
                                                  orgNotifier
                                                          .currentOrganization =
                                                      orgNotifier
                                                          .orgList[index];
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context,
                                                          animation1,
                                                          animation2) {
                                                        return OrganizationActivity(
                                                            orgNotifier
                                                                .orgList[index]
                                                                .id);
                                                      },
                                                      transitionsBuilder:
                                                          (context,
                                                              animation1,
                                                              animation2,
                                                              child) {
                                                        return FadeTransition(
                                                          opacity: animation1,
                                                          child: child,
                                                        );
                                                      },
                                                      transitionDuration:
                                                          Duration(
                                                              milliseconds:
                                                                  500),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'Activities_String'),
                                                  style: TextStyle(
                                                      fontSize: 16.0,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );

    return new Container(
      decoration: new BoxDecoration(
        color: Colors.white,
      ),
      child: new Stack(
        children: <Widget>[
          new CustomPaint(
            size: new Size(_width, _height),
            painter: new Background(),
          ),
          body,
        ],
      ),
    );
  }
}
