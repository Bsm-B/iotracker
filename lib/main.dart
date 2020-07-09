import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:vibration/vibration.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  final builder = mqtt.MqttClientPayloadBuilder();

  String broker           = 'broker.mqttdashboard.com';
  int port                = 1883;
  String username         = '';
  String passwd           = '';
  double _temp            = 20;
  
  Timer _timer;
  
  mqtt.MqttClient client;
  mqtt.MqttConnectionState connectionState;

  StreamSubscription subscription;

  void startTimer() {
    const oneSec = const Duration(seconds: 10);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
           /* _getLocation().then((value) {
                      setState(() {
                        userLocation = value;
                      });
            });*/
          builder.clear();
          builder.addString("val");
          print('EXAMPLE:: <<<< PUBLISH 1 >>>>');
          client.publishMessage("temp/t3", mqtt.MqttQos.exactlyOnce , builder.payload);
          print("data");
        },
      ),
    );
  }

  
  void _connect() async {
    
    startServiceInPlatform();
    client = mqtt.MqttClient(broker, '');
    client.port = port;

    client.logging(on: true);

    client.keepAlivePeriod = 30;

    client.onDisconnected = _onDisconnected;

    Random random = new Random();

   String clientIdentifier = 'android-'+ random.toString()+'0kl68';

    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean() // Non persistent session for testing
        .keepAliveFor(30)
        .withWillQos(mqtt.MqttQos.atMostOnce);
    print('[MQTT client] MQTT client connecting....');
    client.connectionMessage = connMess;

    startTimer();

    try {
      await client.connect(username, passwd);
    } catch (e) {
      print(e);
      _disconnect();
    }

    /// Check if we are connected
    if (client.connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] connected');
      setState(() {
        connectionState = client.connectionState;
      });
    
    } else {
      print('[MQTT client] ERROR: MQTT client connection failed - '
          'disconnecting, state is ${client.connectionState}');
      _disconnect();
    }

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    subscription = client.updates.listen(_onMessage);

    _subscribeToTopic("temp/t1");
  }

  void _disconnect() {
    print('[MQTT client] _disconnect()');
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
    setState(() {
      //topics.clear();
      connectionState = client.connectionState;
      client = null;
      subscription.cancel();
      subscription = null;
    });
    print('[MQTT client] MQTT client disconnected');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    print(event.length);
    final mqtt.MqttPublishMessage recMess =
    event[0].payload as mqtt.MqttPublishMessage;
    final String message =
    mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

 
    print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
        'payload is <-- ${message} -->');
    print(client.connectionState);
    print("[MQTT client] message with topic: ${event[0].topic}");
    print("[MQTT client] message with message: ${message}");
    setState(() {
      _temp = double.parse(message);
      
      if (_temp == 10){
        Vibration.vibrate(pattern: [100, 500]); //A 

      }else if( _temp == 20){
        Vibration.vibrate(pattern: [100, 500, 100, 800]); //B

      }else if(_temp == 30){
        Vibration.vibrate(pattern: [100, 500, 100, 500, 100, 800]); //C

      }else if(_temp == 40){
        Vibration.vibrate(pattern: [100, 500, 50,500, 50, 500,50, 800]);

      }else if(_temp == 50){
        Vibration.vibrate(duration: 1500, amplitude: 20);

      }


    });
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
        print('[MQTT client] Subscribing to ${topic.trim()}');
        client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
    }
  }

  void startServiceInPlatform() async {

    if(Platform.isAndroid){
      var methodChannel = MethodChannel("com.retroportalstudio.messages");
      String data = await methodChannel.invokeMethod("startService");
      debugPrint(data);
    }
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: RaisedButton(
            child: Text("Start Background"),
            onPressed: (){
                  startServiceInPlatform();
            }

        ),
      ),
    );
  }
}


