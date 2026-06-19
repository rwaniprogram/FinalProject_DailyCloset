import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

// --- [DATA MODELS] ---
enum ClothesSeason { summer, springFall, winter, all }

class MyClothes {
  final String imagePath;
  final String category; // "상의", "하의"
  final ClothesSeason season;
  final bool isAsset;
  MyClothes({required this.imagePath, required this.category, required this.season, this.isAsset = false});
}

// 오리지널 아카이브 샘플 이미지 데이터 세트
List<MyClothes> globalMyCloset = [
  MyClothes(imagePath: "assets/wearimage/sampleimage_1.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sampleimage_2.png", category: "하의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_5.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_6.jpg", category: "상의", season: ClothesSeason.winter, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_7.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_8.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_4.jpg", category: "하의", season: ClothesSeason.summer, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_3.jpg", category: "상의", season: ClothesSeason.summer, isAsset: true),
];

class WeatherData {
  final String temp; final String location; final String description; final int weatherId; final int timezone;
  final double referenceTemp;
  WeatherData({required this.temp, required this.location, required this.description, required this.weatherId, required this.timezone, required this.referenceTemp});
}

class OutfitSet {
  final String description;
  OutfitSet({required this.description});
}

// --- [BUSINESS SERVICES] ---
class WeatherService {
  static const String apiKey = '1dc33607db9cbe1dbdd93317a1a5c360';
  static Future<Map<String, dynamic>?> fetchByGPS() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 5));
      final res = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&appid=$apiKey&units=metric&lang=kr'));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }
  static Future<Map<String, dynamic>?> fetchByCity(String city) async {
    try {
      final res = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=kr'));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DAILY CLOSET',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
      home: const SplashScreen(),
    );
  }
}

// --- [SCREENS: SPLASH] (3D 문열림 애니메이션 오프닝 완벽 보존) ---
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swing, _fade;
  Map<String, dynamic>? _initialData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _swing = Tween<double>(begin: 0.0, end: pi / 1.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9)));
    _autoStart();
  }

  Future<void> _autoStart() async {
    _controller.forward();
    _initialData = await WeatherService.fetchByGPS();
    if (_initialData == null) {
      _initialData = await WeatherService.fetchByCity("Seoul");
    }
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => MainPage(initialRaw: _initialData)));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4740D4),
      body: AnimatedBuilder(animation: _controller, builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return Stack(children: [
          Center(child: Opacity(opacity: _fade.value, child: Image.asset("assets/wearimage/logo_main.png", width: 280, errorBuilder: (c,e,s)=>const Text("ILLUSION ARCHIVE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2))))),
          Positioned(left: 0, child: Transform(alignment: Alignment.centerLeft, transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(_swing.value), child: SizedBox(width: size.width * 0.5, height: size.height, child: Image.asset("assets/wearimage/door_left.png", fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.black26))))),
          Positioned(right: 0, child: Transform(alignment: Alignment.centerRight, transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-_swing.value), child: SizedBox(width: size.width * 0.5, height: size.height, child: Image.asset("assets/wearimage/door_right.png", fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.black38))))),
        ]);
      }),
    );
  }
}

// --- [SCREENS: MAIN 제어 센터] (5대 탭바 구조) ---
class MainPage extends StatefulWidget {
  final Map<String, dynamic>? initialRaw;
  const MainPage({super.key, this.initialRaw});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _idx = 0;
  WeatherData? _weather;

  final List<Map<String, dynamic>> _ootdList = [
    {
      "date": "2026-06-19",
      "temp": "23°C",
      "style": "시티보이 린넨 스타일",
      "memo": "선선하고 기분 좋은 날씨라 린넨 자켓에 슬랙스를 매칭해 보았습니다.",
      "imagePath": "assets/wearimage/sampleimage_1.jpg",
      "isAsset": true
    }
  ];

  void _addOotdLog(String style, String temp, String memo, String imgPath, bool isAsset) {
    setState(() {
      _ootdList.insert(0, {
        "date": DateTime.now().toString().split(' ')[0],
        "temp": temp.contains("°") ? temp : "$temp°C",
        "style": style,
        "memo": memo,
        "imagePath": imgPath,
        "isAsset": isAsset,
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialRaw != null) _applyRaw(widget.initialRaw!);
  }

  void _applyRaw(Map<String, dynamic> raw) {
    double temp = raw['main']['temp'].toDouble();
    setState(() {
      _weather = WeatherData(temp: temp.toInt().toString(), location: raw['name'].toUpperCase(), description: raw['weather'][0]['description'], weatherId: raw['weather'][0]['id'], timezone: raw['timezone'], referenceTemp: temp);
    });
  }
  void updateWeather(WeatherData d) => setState(() => _weather = d);
  void jumpToTab(int i) => setState(() => _idx = i);

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      RecommendTab(weather: _weather, onGPS: _applyRaw),
      const ClosetTab(),
      SearchTab(onUpdate: updateWeather, jumpTab: jumpToTab),
      OotdTab(ootdList: _ootdList, weather: _weather, onAddOotd: _addOotdLog),
      MyPageTab(ootdCount: _ootdList.length, ootdList: _ootdList),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFF4740D4),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny_outlined), label: '추천'),
          BottomNavigationBarItem(icon: Icon(Icons.door_sliding_outlined), label: '클로젯'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'OOTD'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '마이'),
        ],
      ),
    );
  }
}

// ==========================================
// 1️⃣ [TAB 1: RECOMMEND] (💡 버그 유발 칩을 버리고, 100% 가시성을 확보한 수제 캡슐 버튼 장착)
// ==========================================
class RecommendTab extends StatefulWidget {
  final WeatherData? weather; final Function(Map<String, dynamic>) onGPS;
  const RecommendTab({super.key, this.weather, required this.onGPS});

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab> {
  bool _useMyClothes = false;
  int _setIdx = 0;
  final PageController _pageCtrl = PageController();

  @override
  Widget build(BuildContext context) {
    if (widget.weather == null) {
      return const Scaffold(backgroundColor: Color(0xFF4740D4), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 25), Text("실시간 기상 기전을 동기화 중입니다...", style: TextStyle(color: Colors.white70, fontSize: 14))])));
    }

    final w = widget.weather!;
    final s = StyleEngine.getStyleData(double.parse(w.temp), w.description, w.weatherId);
    final double currentTemp = double.parse(w.temp);
    ClothesSeason targetSeason = currentTemp >= 28 ? ClothesSeason.summer : currentTemp >= 12 ? ClothesSeason.springFall : ClothesSeason.winter;

    final Color bgColor = s["color"];
    final Color txtColor = s["txtColor"];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: bgColor,
      child: Stack(children: [
        if (s["isRain"]) Positioned.fill(child: Opacity(opacity: 0.15, child: Image.asset("assets/wearimage/rain_bg.jpg", fit: BoxFit.cover, errorBuilder:(c,e,st)=>Container(color: Colors.black26)))),
        Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            onPressed: () async {
              final raw = await WeatherService.fetchByGPS();
              if (raw != null) widget.onGPS(raw);
            },
            child: const Icon(Icons.my_location, color: Color(0xFF4740D4)),
          ),
          appBar: AppBar(
            toolbarHeight: 40, centerTitle: true, backgroundColor: Colors.transparent, elevation: 0,
            title: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Text('DAILY CLOSET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: txtColor)), const SizedBox(width: 4), Image.asset("assets/wearimage/logo_symbol.png", height: 28, errorBuilder:(c,e,st)=>Icon(Icons.check_circle, color: txtColor))]),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 10),
              Text(w.location, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11, color: txtColor.withOpacity(0.6))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${w.temp}°C', style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, letterSpacing: -5, color: txtColor)),
                Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s["weather_display"], style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: txtColor))),
              ]),
              const SizedBox(height: 20),

              // 💡 [초강력 가시성 패치] 렌더링 버그가 나던 FilterChip을 완전히 삭제하고, 눈에 안 띌 수가 없는 독자적인 '수제 와이드 토글 바' 배치 완료!
              GestureDetector(
                onTap: () => setState(() => _useMyClothes = !_useMyClothes),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _useMyClothes ? Colors.white : Colors.black.withValues(alpha: 0.15), // 온오프 색상 반전 명확화
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2.5), // 두꺼운 순백색 테두리로 가시성 폭발
                    boxShadow: _useMyClothes
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _useMyClothes ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        color: _useMyClothes ? const Color(0xFF4740D4) : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "내 옷장 데이터로 매칭 받기",
                        style: TextStyle(
                          color: _useMyClothes ? const Color(0xFF4740D4) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_useMyClothes) ...[
                _buildMyClothesCuration(targetSeason, currentTemp, txtColor)
              ] else ...[
                _buildDefaultCuration(s, txtColor)
              ],
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMyClothesCuration(ClothesSeason targetSeason, double currentTemp, Color txt) {
    var matchingTops = globalMyCloset.where((c) => c.category == "상의" && c.season == targetSeason).toList();
    var matchingBottoms = globalMyCloset.where((c) => c.category == "하의" && c.season == targetSeason).toList();
    bool hasMatch = matchingTops.isNotEmpty && matchingBottoms.isNotEmpty;

    if (!hasMatch) {
      return Container(
        height: 220, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: Center(child: Text("현재 기온(${currentTemp.toInt()}°C) 조건에 맞는\n소장용 의상이 내 클로젯에 부족합니다.", textAlign: TextAlign.center, style: TextStyle(color: txt.withOpacity(0.6), height: 1.4))),
      );
    }

    return Column(children: [
      Row(children: [
        Expanded(child: _buildCurationImg(matchingTops.last)),
        const SizedBox(width: 12),
        Expanded(child: _buildCurationImg(matchingBottoms.last)),
      ]),
      const SizedBox(height: 14),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: txt.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: Text("클로젯에 등록하신 아카이브 중에서 현재 기온 환경에 가장 적절한 상/하의 컬렉션 조합입니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: txt, fontWeight: FontWeight.w600)),
      )
    ]);
  }

  Widget _buildDefaultCuration(Map<String, dynamic> s, Color txt) {
    final List<OutfitSet> sets = s["sets"];
    String sc = s["scenario"];
    bool isR = s["isRain"];

    return Column(children: [
      SizedBox(height: 290, child: PageView.builder(
        controller: _pageCtrl, itemCount: sets.length, onPageChanged: (i) => setState(() => _setIdx = i),
        itemBuilder: (context, idx) {
          return Row(children: [
            Expanded(child: _buildImg(isR ? "assets/wearimage/${sc}_t.jpg" : "assets/wearimage/${sc}_${idx+1}_t.jpg")),
            const SizedBox(width: 12),
            Expanded(child: _buildImg(isR ? "assets/wearimage/${sc}_b.jpg" : "assets/wearimage/${sc}_${idx+1}_b.jpg"))
          ]);
        },
      )),
      if (sets.length > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(sets.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: _setIdx == i ? txt : txt.withOpacity(0.2)))))),
      const SizedBox(height: 15),
      Text("오늘의 코디 추천", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: txt.withOpacity(0.6))),
      Text(s["lookName"], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: txt)),
      const SizedBox(height: 10),
      Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: txt.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Text("${s["infoBox"]}\n(${sets.isNotEmpty && sets.length > _setIdx ? sets[_setIdx].description : ''})", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: txt, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _buildCurationImg(MyClothes item) => ClipRRect(borderRadius: BorderRadius.circular(15), child: AspectRatio(aspectRatio: 0.85, child: Image.asset(item.imagePath, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.white24, child: const Icon(Icons.checkroom, color: Colors.white)))));
  Widget _buildImg(String p) => ClipRRect(borderRadius: BorderRadius.circular(15), child: AspectRatio(aspectRatio: 0.85, child: Image.asset(p, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.white10, child: Center(child: Text("📸\n${p.split('/').last}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 11)))))));
}

// ==========================================
// 2️⃣ [TAB 2: CLOSET] 내 옷장 격자 리스트 탭
// ==========================================
class ClosetTab extends StatefulWidget {
  const ClosetTab({super.key});
  @override
  State<ClosetTab> createState() => _ClosetTabState();
}

class _ClosetTabState extends State<ClosetTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadClothes() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() {
      globalMyCloset.insert(0, MyClothes(imagePath: img.path, category: "상의", season: ClothesSeason.springFall, isAsset: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        title: const Text('MY ARCHIVE CLOSET', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true, backgroundColor: Colors.transparent, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF4740D4)), onPressed: _uploadClothes)],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 12, childAspectRatio: 0.75),
        itemCount: globalMyCloset.length,
        itemBuilder: (context, i) {
          final item = globalMyCloset[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.white,
              child: item.isAsset
                  ? Image.asset(item.imagePath, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)))
                  : Image.file(File(item.imagePath), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 3️⃣ [TAB 3: SEARCH] 검색 탭
// ==========================================
class SearchTab extends StatelessWidget {
  final Function(WeatherData) onUpdate; final Function(int) jumpTab;
  const SearchTab({super.key, required this.onUpdate, required this.jumpTab});

  @override
  Widget build(BuildContext context) {
    final searchCtrl = TextEditingController();
    return Scaffold(
      backgroundColor: const Color(0xFF4740D4),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 35), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextField(
          controller: searchCtrl,
          onSubmitted: (v) => _executeSearch(v, context),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
              hintText: 'Search City or Temp...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: const BorderSide(color: Colors.white, width: 2))
          ),
        ),
        const SizedBox(height: 25),
        const Text("지역(London) 또는 기온(25)을 입력하여\n실시간 맞춤 코디를 추천받으세요.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
      ]))),
    );
  }

  void _executeSearch(String v, BuildContext context) async {
    if (v.isEmpty) return;
    final double? t = double.tryParse(v);
    if (t != null) {
      onUpdate(WeatherData(temp: t.toInt().toString(), location: "CUSTOM TEMP", description: StyleEngine.getAutoDesc(t), weatherId: 800, timezone: 32400, referenceTemp: t));
    } else {
      final raw = await WeatherService.fetchByCity(v);
      if (raw != null) {
        double ct = raw['main']['temp'].toDouble();
        onUpdate(WeatherData(temp: ct.toInt().toString(), location: raw['name'].toUpperCase(), description: raw['weather'][0]['description'], weatherId: raw['weather'][0]['id'], timezone: raw['timezone'], referenceTemp: ct));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매칭되는 도시 정보를 불러오지 못했습니다.')));
        return;
      }
    }
    jumpTab(0);
  }
}

// ==========================================
// 4️⃣ [TAB 4: OOTD DIARY] OOTD 일기장 탭
// ==========================================
class OotdTab extends StatefulWidget {
  final List<Map<String, dynamic>> ootdList; final WeatherData? weather;
  final Function(String, String, String, String, bool) onAddOotd;
  const OotdTab({super.key, required this.ootdList, this.weather, required this.onAddOotd});

  @override
  State<OotdTab> createState() => _OotdTabState();
}

class _OotdTabState extends State<OotdTab> {
  final _styleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedImgPath;
  bool _isAsset = true;

  Future<void> _pickOotdImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _selectedImgPath = img.path;
        _isAsset = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentTempLabel = widget.weather != null ? "${widget.weather!.temp}°C" : "23°C";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(title: const Text('OOTD DIARY', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("오늘의 데일리 룩 기록하기", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4740D4))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickOotdImage,
                child: Container(
                  height: 130, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: _selectedImgPath == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_outlined, color: Colors.grey), SizedBox(height: 6), Text("오늘 코디 사진 첨부 (클릭)", style: TextStyle(color: Colors.grey, fontSize: 13))])
                      : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_selectedImgPath!), fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _styleCtrl, decoration: const InputDecoration(hintText: "코디 스타일 명칭 (예: 시티보이 캐주얼)", hintStyle: TextStyle(fontSize: 13, color: Colors.grey), contentPadding: EdgeInsets.symmetric(horizontal: 4))),
              TextField(controller: _memoCtrl, decoration: const InputDecoration(hintText: "오늘 날씨에 대한 코디 한줄평 및 메모...", hintStyle: TextStyle(fontSize: 13, color: Colors.grey), contentPadding: EdgeInsets.symmetric(horizontal: 4))),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Chip(
                  avatar: const Icon(Icons.wb_sunny_outlined, size: 14, color: Color(0xFF4740D4)),
                  label: Text("기온 정보: $currentTempLabel", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4740D4))),
                  backgroundColor: const Color(0xFFEFF3FF), side: BorderSide.none,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_styleCtrl.text.isNotEmpty) {
                      String finalPath = _selectedImgPath ?? "assets/wearimage/sampleimage_1.jpg";
                      widget.onAddOotd(_styleCtrl.text, currentTempLabel, _memoCtrl.text, finalPath, _isAsset);
                      _styleCtrl.clear(); _memoCtrl.clear();
                      setState(() { _selectedImgPath = null; _isAsset = true; });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4740D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("기록하기", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ])
            ]),
          ),
          const SizedBox(height: 28),
          const Text("📜 아카이브 다이어리 히스토리", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ...widget.ootdList.map((ootd) => Card(
            color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 75, height: 95,
                    child: ootd["isAsset"] == true
                        ? Image.asset(ootd["imagePath"]!, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.grey.shade200))
                        : Image.file(File(ootd["imagePath"]!), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(ootd["style"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(6)), child: Text(ootd["temp"]!, style: const TextStyle(color: Color(0xFF4740D4), fontWeight: FontWeight.bold, fontSize: 11))),
                  ]),
                  const SizedBox(height: 4),
                  Text(ootd["memo"]!, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: Text("📅 ${ootd["date"]}", style: const TextStyle(color: Colors.grey, fontSize: 11))),
                ]))
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

// ==========================================
// 5️⃣ [TAB 5: MY PAGE] 마이 페이지 탭
// ==========================================
class MyPageTab extends StatelessWidget {
  final int ootdCount; final List<Map<String, dynamic>> ootdList;
  const MyPageTab({super.key, required this.ootdCount, required this.ootdList});

  void _showFriendProfilePopup(BuildContext context, Map<String, String> friend) {
    IconData styleIcon = Icons.star_border_rounded;
    if (friend["name"] == "James") styleIcon = Icons.checkroom_outlined;
    if (friend["name"] == "Sophie") styleIcon = Icons.auto_awesome_outlined;
    if (friend["name"] == "Dan") styleIcon = Icons.explore_outlined;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          CircleAvatar(radius: 36, backgroundColor: const Color(0xFFEFF3FF), child: Text(friend["emoji"]!, style: const TextStyle(fontSize: 36))),
          const SizedBox(height: 16),
          Text(friend["name"]!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F5F2), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(styleIcon, color: const Color(0xFF4740D4), size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text("${friend["name"]} 님은 현재 '${friend["style"]}' 무드를 메인으로 아카이빙 중입니다.", style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${friend["name"]} 님의 아카이브 타임라인 계정 피드로 안전 연동 통신을 라우팅합니다.')));
              },
              icon: const Icon(Icons.sensor_door_outlined, size: 18),
              label: Text("${friend["name"]} 계정 방문하기", style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4740D4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mockFriends = [
      {"name": "James", "emoji": "🦖", "style": "아메카지 워크웨어 스타일"},
      {"name": "Sophie", "emoji": "🐰", "style": "미니멀 톤온톤 오피스룩"},
      {"name": "Dan", "emoji": "🦊", "style": "스트릿 고프코어 기능성 룩"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(title: const Text('MY PAGE', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(children: [
            const CircleAvatar(radius: 40, backgroundColor: Colors.black12, child: Text("👤", style: TextStyle(fontSize: 40))),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text("패션피플_홍길동", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("스타일 등급: 트렌드세터", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ])
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _statBox("소장 중인 옷 벌 수", "${globalMyCloset.length}벌")),
            const SizedBox(width: 16),
            Expanded(child: _statBox("기록된 OOTD 일기", "$ootdCount건")),
          ]),
          const SizedBox(height: 32),
          const Text("👥 친구들의 최근 코디 (실시간 피드 프리뷰)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: mockFriends.length,
              itemBuilder: (context, index) {
                final friend = mockFriends[index];
                return GestureDetector(
                  onTap: () => _showFriendProfilePopup(context, friend),
                  child: Container(
                    width: 160, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEAEAEA))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(friend["emoji"]!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(friend["name"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                      const SizedBox(height: 8),
                      Text(friend["style"]!, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String l, String v) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)]), child: Column(children: [Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13)), const SizedBox(height: 6), Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]));
}

// --- [STYLE ENGINE 기상 큐레이션 연산기] ---
class StyleEngine {
  static String getAutoDesc(double t) => t >= 30 ? "무더위" : t >= 20 ? "맑음" : t >= 10 ? "선선함" : "추움";
  static Map<String, dynamic> getStyleData(double temp, String condition, int id) {
    String d = condition; final Map<String, String> nk = {'박무': '안개', '연무': '옅은 안개', '실비': '약한 비', '온흐림': '흐림', '튼구름': '구름 많음', '조각 구름': '구름 조금'};
    nk.forEach((k, v) => d = d.contains(k) ? v : d);
    bool isR = (id >= 200 && id < 600); List<OutfitSet> sets = []; String sc, ln, ib; Color color;
    if (isR) {
      color = const Color(0xFF455A64);
      if (temp >= 23) { sc = "rain_hot"; ln = "썸머 레인 쉴드 룩"; ib = "습한 날씨에도 쾌적함을 유지하세요."; sets = [OutfitSet(description: "레인코트와 나일론 쇼츠")]; }
      else if (temp >= 12) { sc = "rain_mild"; ln = "어반 레인 룩"; ib = "방풍 방수가 되는 아우터를 챙기세요."; sets = [OutfitSet(description: "윈드브레이커와 카고 팬츠")]; }
      else { sc = "rain_cold"; ln = "윈터 레인 워머 룩"; ib = "추위와 비를 동시에 막아야 합니다."; sets = [OutfitSet(description: "경량 패딩과 방수 코트")]; }
    } else {
      color = temp >= 28 ? const Color(0xFFFFAB40) : temp >= 17 ? const Color(0xFF689F38) : const Color(0xFF64B5F6);
      if (temp >= 28) { sc = "02"; ln = "시원한 린넨 룩"; ib = "무더운 한여름, 린넨 소재로 쾌적함을 더하세요."; sets = [OutfitSet(description: "린넨 셔츠와 면 반바지"), OutfitSet(description: "시어서커 셔츠와 와이드 팬츠"), OutfitSet(description: "그래픽 티셔츠와 나일론 쇼츠")]; }
      else if (temp >= 17) { sc = "05"; ln = "베이직 시티 캐주얼"; ib = "선선한 바람이 부네요. 가디건을 추천해요."; sets = [OutfitSet(description: "V넥 가디건과 연청 데님"), OutfitSet(description: "옥스퍼드 셔츠와 치노 팬츠"), OutfitSet(description: "오버핏 맨투맨과 스웻 팬츠")]; }
      else { sc = "07"; ln = "모던 가죽 코디"; ib = "쌀쌀한 날씨, 무게감 있는 소재를 골라보세요."; sets = [OutfitSet(description: "라이더 자켓과 블랙 팬츠"), OutfitSet(description: "헤비 가디건과 코듀로이 팬츠"), OutfitSet(description: "퀼팅 자켓과 생지 데님")]; }
    }
    return {"weather_display": d, "color": color, "txtColor": Colors.white, "lookName": ln, "infoBox": ib, "scenario": sc, "sets": sets, "isRain": isR};
  }
}