import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  //api key
  final _WeatherService = WeatherService(apiKey: dotenv.env['API_KEY']!);
  Weather? _weather;

  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _videoError;

  //_FETCH WEATHER DATA
  _fetchWeather() async {
    //get the current city
    String cityName = await _WeatherService.getCurrentCity();

    //get weather for city
    try {
      final weather = await _WeatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
      // Initialize video after weather data is fetched
      _initializeVideoPlayer();
    }
    //any error
    catch (e) {
      print(e);
    }
  }

  // Get appropriate video file based on weather condition
  String _getWeatherVideo() {
    if (_weather == null) return 'assets/Sunny Day.mp4'; // Default

    switch (_weather!.mainCondition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return 'assets/Sunny Day.mp4';
      case 'rain':
      case 'drizzle':
      case 'shower':
        return 'assets/Cloud Rain.mp4';
      case 'thunderstorm':
      case 'thunder':
        return 'assets/Thunder.mp4';
      case 'clouds':
      case 'cloudy':
      case 'overcast':
      case 'mist':
      case 'fog':
      case 'haze':
      default:
        return 'assets/Cloud Rain.mp4';
    }
  }

  // Initialize video player based on weather condition
  _initializeVideoPlayer() async {
    // Dispose previous controller if exists
    _videoController?.dispose();

    setState(() {
      _isVideoInitialized = false;
      _videoError = null;
    });

    String videoPath = _getWeatherVideo();
    print('Trying to load video: $videoPath'); // Debug print

    _videoController = VideoPlayerController.asset(videoPath);

    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      // Set video to loop and play
      _videoController!.setLooping(true);
      _videoController!.play();
      print('Video loaded successfully: $videoPath'); // Debug print
    } catch (e) {
      print('Error initializing video $videoPath: $e');

      // Try alternative file names (in case of different naming)
      List<String> fallbackVideos = [
        'assets/sunny_day.mp4',
        'assets/cloud_rain.mp4',
        'assets/thunder.mp4',
        'assets/weather.mp4', // Original file name you had
      ];

      bool videoLoaded = false;
      for (String fallback in fallbackVideos) {
        if (fallback != videoPath) {
          // Don't try the same file again
          try {
            print('Trying fallback video: $fallback');
            _videoController = VideoPlayerController.asset(fallback);
            await _videoController!.initialize();
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.play();
            print('Fallback video loaded: $fallback');
            videoLoaded = true;
            break;
          } catch (e2) {
            print('Fallback video $fallback failed: $e2');
          }
        }
      }

      if (!videoLoaded) {
        setState(() {
          _videoError = 'Could not load any video files';
        });
      }
    }
  }

  // Get weather icon as fallback
  IconData _getWeatherIcon() {
    if (_weather == null) return Icons.wb_sunny;

    switch (_weather!.mainCondition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'clouds':
      case 'cloudy':
        return Icons.cloud;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }

  //init state
  @override
  void initState() {
    super.initState();

    //fetch weather on startup (video will be initialized after weather data is received)
    _fetchWeather();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: AppBar(
        title: const Text('Weather App'),
        centerTitle: true,
        backgroundColor: Colors.blue[300],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //city Name
            Text(
              _weather?.cityName ?? 'loading city...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),

            SizedBox(height: 20),

            // Video animation with fallback
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isVideoInitialized && _videoController != null
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : _videoError != null
                    ? Container(
                        color: Colors.blue[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getWeatherIcon(),
                              size: 80,
                              color: Colors.blue[700],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Video Error',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.blue[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blue[700],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading animation...',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            SizedBox(height: 20),

            //temperature
            Text(
              _weather != null
                  ? '${_weather!.temperature.round()}°C'
                  : 'Loading temperature...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),

            SizedBox(height: 10),

            // Weather condition
            Text(
              _weather?.mainCondition ?? 'Loading condition...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
