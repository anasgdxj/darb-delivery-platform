part of 'app_shell.dart';

class DriverLocationReporter {
  static Timer? _timer;
  static bool _sending = false;
  static bool _refreshing = false;
  static bool _refreshRequested = false;
  static bool _enabled = false;
  static bool _observerRegistered = false;
  static int _generation = 0;

  static final WidgetsBindingObserver _lifecycleObserver =
      _DriverLocationLifecycleObserver();

  static void start() {
    _enabled = true;
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
      _observerRegistered = true;
    }
    if (_timer != null || _refreshing) return;
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    if (!_enabled) return;
    if (_refreshing) {
      _refreshRequested = true;
      return;
    }
    _refreshing = true;
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;
    try {
      final driver = Map<String, dynamic>.from(await Api.instance.get('/drivers/me'));
      if (generation != _generation ||
          driver['status'] != 'APPROVED' ||
          driver['isOnline'] != true) return;
      await _sendLocation();
      if (generation != _generation) return;
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _sendLocation(),
      );
    } catch (_) {
      _timer?.cancel();
      _timer = null;
    } finally {
      _refreshing = false;
      if (_refreshRequested && _enabled) {
        _refreshRequested = false;
        unawaited(refresh());
      }
    }
  }

  static void pause() {
    _generation++;
    _refreshRequested = false;
    _timer?.cancel();
    _timer = null;
  }

  static void stop() {
    _enabled = false;
    pause();
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      _observerRegistered = false;
    }
  }

  static Future<void> _sendLocation() async {
    if (!_enabled || _sending) return;
    _sending = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      if (!_enabled) return;
      await Api.instance.patch('/drivers/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (_) {
      // Location failures must not interrupt the driver's order workflow.
    } finally {
      _sending = false;
    }
  }
}

class _DriverLocationLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DriverLocationReporter.refresh());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      DriverLocationReporter.pause();
    }
  }
}

class DriverAvailable extends StatefulWidget {const DriverAvailable({super.key});@override State<DriverAvailable> createState()=>_DriverAvailableState();}
class _DriverAvailableState extends State<DriverAvailable>{bool loading=true,working=false;Map<String,dynamic>? driver;String? error;@override void initState(){super.initState();_load();}Future<void> _load()async{try{driver=Map<String,dynamic>.from(await Api.instance.get('/drivers/me'));error=null;DriverLocationReporter.start();}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}Future<void> _toggle(bool value)async{setState(()=>working=true);try{driver=Map<String,dynamic>.from(await Api.instance.patch('/drivers/online',{'isOnline':value}));error=null;DriverLocationReporter.refresh();}catch(e){error=e.toString();}finally{if(mounted)setState(()=>working=false);}}@override Widget build(BuildContext context){if(loading)return Center(child:CircularProgressIndicator());if(error!=null)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!),TextButton(onPressed:(){setState(()=>loading=true);_load();},child:Text(dt('إعادة المحاولة')))])));final approved=driver?['status']=='APPROVED';return Column(children:[Padding(padding:const EdgeInsets.all(14),child:DarbGlassCard(child:SwitchListTile(value:driver?['isOnline']==true&&approved,onChanged:!approved||working?null:_toggle,title:Text(dt('متصل لاستلام الطلبات')),subtitle:Text(approved?'فعّل الحالة لتظهر لك الطلبات الجاهزة':'حساب السائق بانتظار اعتماد الإدارة')))),if(approved&&driver?['isOnline']==true)Expanded(child:_DataList(path:'/orders/driver/available',title: dt('طلبات جاهزة للاستلام'),empty: dt('لا توجد طلبات متاحة حالياً')))else Expanded(child:Center(child:Text(dt('اتصل لاستقبال الطلبات بعد اعتماد حسابك'))))]);}}
class DriverOrders extends StatelessWidget {const DriverOrders({super.key});@override Widget build(BuildContext context)=>_DataList(path:'/orders/driver/mine',title: dt('توصيلاتي'),empty: dt('لا توجد توصيلات حالياً'));}
class _DataList extends StatefulWidget {final String path,title,empty;const _DataList({super.key,required this.path,required this.title,required this.empty});@override State<_DataList> createState()=>_DataListState();}
class _DataListState extends State<_DataList>{bool loading=true;String? error;String? _workingOrderId;List rows=[];@override void initState(){super.initState();_load();}Future<void> _load()async{setState(()=>loading=true);try{rows=await Api.instance.get(widget.path) as List;error=null;}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext context)=>RefreshIndicator(
  onRefresh:_load,
  color: DarbColors.brandForeground,
  child:ListView(
    physics:const AlwaysScrollableScrollPhysics(),
    padding:const EdgeInsets.fromLTRB(18,18,18,28),
    children:[
      Container(
        padding:const EdgeInsets.all(18),
        decoration:BoxDecoration(
          gradient:LinearGradient(
            begin:Alignment.topRight,
            end:Alignment.bottomLeft,
            colors:[DarbColors.forestSoft,DarbColors.forest],
          ),
          borderRadius:BorderRadius.circular(DarbRadius.xl),
          boxShadow:DarbElevation.card,
        ),
        child:Row(children:[
          Expanded(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(widget.title,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),
              const SizedBox(height:6),
              Text(
                loading?dt('جارٍ تحديث البيانات'):error!=null?dt('تعذر تحديث القائمة'):dt('اسحب للأسفل لتحديث الطلبات'),
                style:TextStyle(color:Colors.white.withValues(alpha:.72),fontSize:12),
              ),
            ],
          )),
          Container(
            width:46,height:46,
            decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(15)),
            child:Icon(Icons.receipt_long_rounded,color:DarbColors.mint,size:23),
          ),
        ]),
      ),
      const SizedBox(height:18),
      if(loading) ...List.generate(3,(index)=>Padding(
        padding:const EdgeInsets.only(bottom:10),
        child:Container(
          height:116,
          decoration:BoxDecoration(color:DarbColors.surface,borderRadius:BorderRadius.circular(DarbRadius.lg),border:Border.all(color:DarbColors.line)),
          child:const Center(child:LinearProgressIndicator(minHeight:2)),
        ),
      )),
      if(error!=null)_ErrorPanel(message:error!,retry:_load),
      if(!loading&&error==null&&rows.isEmpty)_EmptyPanel(text:widget.empty),
      if(!loading&&error==null)for(var index=0;index<rows.length;index++)DarbFadeSlide(
        delay:DarbMotion.staggerDelay(index.clamp(0,5).toInt()),
        child:_orderCard(rows[index]),
      ),
    ],
  ),
);
String _statusLabel(String status, {required bool peer}) {
  switch (status) {
    case 'PENDING':
      return peer ? dt('بانتظار عروض السائقين') : dt('بانتظار التأكيد');
    case 'ACCEPTED':
      return dt('تم قبول الطلب');
    case 'PREPARING':
      return dt('قيد التحضير');
    case 'READY':
      return dt('جاهز للاستلام');
    case 'ASSIGNED':
      return dt('تم تعيين سائق');
    case 'PICKED_UP':
      return dt('تم استلام الطلب');
    case 'DELIVERED':
      return dt('تم التسليم');
    case 'CANCELLED':
      return dt('ملغي');
    default:
      return status;
  }
}
Widget _orderCard(dynamic row){
  final id=row['id']?.toString()??'';
  final status=row['status']?.toString()??'';
  final peer=row['type']=='PEER_DELIVERY';
  final pickup=row['pickupAddress']?.toString();
  final destination=(row['address'] is Map)?row['address']['details']?.toString():null;
  final actions=<Widget>[];
  if(widget.path=='/orders/vendor'){
    if(status=='PENDING')actions.add(_action(id,dt('قبول'),'ACCEPTED'));
    if(status=='ACCEPTED')actions.add(_action(id,dt('بدء التحضير'),'PREPARING'));
    if(status=='PREPARING')actions.add(_action(id,dt('جاهز للاستلام'),'READY'));
  }
  if(widget.path=='/orders/driver/available'&&!peer)actions.add(FilledButton.icon(onPressed:_workingOrderId==null?()=>_claim(id):null,icon:_workingOrderId==id?SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Icon(Icons.check_rounded),label:Text(dt('استلام الطلب'))));
  if(widget.path=='/orders/driver/available'&&peer)actions.add(_DriverOfferAction(orderId:id,onSent:_load));
  if(widget.path=='/orders/mine'&&(status=='ASSIGNED'||status=='PICKED_UP'))actions.add(TextButton.icon(onPressed:()=>_track(id),icon:Icon(Icons.location_on_outlined),label:Text(dt('موقع السائق'))));
  if(widget.path=='/orders/driver/mine'){
    if(status=='ASSIGNED')actions.add(_action(id,dt('تم الاستلام'),'PICKED_UP'));
    if(status=='PICKED_UP')actions.add(_action(id,dt('تم التسليم'),'DELIVERED'));
  }
  final statusColor=switch(status){
    'DELIVERED'=>DarbColors.success,
    'CANCELLED'=>DarbColors.danger,
    'PENDING'=>DarbColors.warning,
    _=>DarbColors.info,
  };
  return DarbGlassCard(
    margin:const EdgeInsets.only(bottom:12),
    child:Padding(
      padding:const EdgeInsets.all(15),
      child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          Row(children:[
            Container(
              width:44,height:44,
              decoration:BoxDecoration(color:DarbColors.mint.withValues(alpha:.38),borderRadius:BorderRadius.circular(14)),
              child:Icon(peer?Icons.local_shipping_rounded:Icons.shopping_bag_outlined,color: DarbColors.brandForeground),
            ),
            const SizedBox(width:11),
            Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(peer?dt('طلب توصيل مستقل'):'${dt('طلب')} ${row['orderNumber']??id}',style:TextStyle(fontWeight:FontWeight.w900,fontSize:14,color:DarbColors.ink)),
                const SizedBox(height:3),
                Text('${dt('رقم الطلب')}: ${row['orderNumber']??id}',style:TextStyle(color:DarbColors.muted,fontSize:11)),
              ],
            )),
            Container(
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),
              decoration:BoxDecoration(color:statusColor.withValues(alpha:.10),borderRadius:BorderRadius.circular(DarbRadius.pill)),
              child:Text(_statusLabel(status,peer:peer),style:TextStyle(color:statusColor,fontSize:10,fontWeight:FontWeight.w800)),
            ),
          ]),
          const SizedBox(height:13),
          Container(
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),
            decoration:BoxDecoration(color:DarbColors.canvas,borderRadius:BorderRadius.circular(13)),
            child:Row(children:[
              Expanded(child:Text(peer&&row['deliveryFee']==0?dt('بانتظار عروض السائقين'):dt('قيمة الطلب'),style:TextStyle(color:DarbColors.muted,fontSize:11))),
              Text('${row['total']??''} ${row['currency']??''}',style:TextStyle(color: DarbColors.brandForeground,fontSize:14,fontWeight:FontWeight.w900)),
            ]),
          ),
          if(peer&&row['distanceKm']!=null)Padding(
            padding:const EdgeInsets.only(top:10),
            child:Row(children:[
              Icon(Icons.route_rounded,size:16,color:DarbColors.muted),
              const SizedBox(width:6),
              Text(dt('مسافة التوصيل: ${(row['distanceKm'] as num).toStringAsFixed(1)} كم'),style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
            ]),
          ),
          if(peer&&pickup!=null)ListTile(
            dense:true,contentPadding:EdgeInsets.zero,
            leading:Icon(Icons.trip_origin_rounded,color: DarbColors.brandForeground),
            title:Text(dt('الاستلام'),style:TextStyle(fontSize:11,color:DarbColors.muted)),
            subtitle:Text(pickup,style:const TextStyle(fontWeight:FontWeight.w700)),
          ),
          if(peer&&destination!=null)ListTile(
            dense:true,contentPadding:EdgeInsets.zero,
            leading:Icon(Icons.flag_rounded,color:DarbColors.success),
            title:Text(dt('التسليم'),style:TextStyle(fontSize:11,color:DarbColors.muted)),
            subtitle:Text(destination,style:const TextStyle(fontWeight:FontWeight.w700)),
          ),
          if(peer&&widget.path=='/orders/mine'&&status=='PENDING')_CustomerDeliveryOffers(orderId:id,onSelected:_load),
          if(actions.isNotEmpty)...[
            const Divider(height:20),
            Wrap(spacing:8,runSpacing:8,children:actions),
          ],
        ],
      ),
    ),
  );
}
Widget _action(String id,String label,String status)=>TextButton(onPressed:_workingOrderId==null?()=>_changeStatus(id,status):null,child:_workingOrderId==id?SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):Text(label));
Future<void> _track(String id)async{try{final location=await Api.instance.get('/orders/$id/driver-location');if(location is! Map||location['available']!=true){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(dt('لم يشارك السائق موقعه بعد'))));return;}final lat=location['latitude'];final lng=location['longitude'];final uri=Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');if(!await launchUrl(uri,mode:LaunchMode.externalApplication))throw Exception('تعذر فتح الخرائط');}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}Future<void> _changeStatus(String id,String status)async{if(_workingOrderId!=null)return;setState(()=>_workingOrderId=id);try{await Api.instance.patch('/orders/$id/status',{'status':status});await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_workingOrderId=null);}}
Future<void> _claim(String id)async{if(_workingOrderId!=null)return;setState(()=>_workingOrderId=id);try{await Api.instance.post('/orders/$id/claim',{});await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>_workingOrderId=null);}}
}


class _DriverOfferAction extends StatelessWidget {
  final String orderId;
  final Future<void> Function() onSent;
  const _DriverOfferAction({required this.orderId,required this.onSent});
  Future<void> _offer(BuildContext context) async {
    final price=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(dt('تقديم أجرة التوصيل')),
      content:TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText: dt('الأجرة بالليرة السورية الجديدة'),hintText: dt('أدخل المبلغ'))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(dt('إلغاء'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(dt('إرسال العرض')))],
    ));
    final amount=double.tryParse(price.text.trim());
    price.dispose();
    if(ok!=true||amount==null||amount<=0)return;
    try{
      await Api.instance.post('/orders/$orderId/offers',{'amount':amount});
      if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(dt('تم إرسال عرضك للعميل'))));await onSent();}
    }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override Widget build(BuildContext context)=>FilledButton.icon(onPressed:()=>_offer(context),icon:Icon(Icons.local_offer_outlined),label:Text(dt('تحديد الأجرة')));
}

class _CustomerDeliveryOffers extends StatefulWidget {
  final String orderId;
  final Future<void> Function() onSelected;
  const _CustomerDeliveryOffers({required this.orderId,required this.onSelected});
  @override State<_CustomerDeliveryOffers> createState()=>_CustomerDeliveryOffersState();
}
class _CustomerDeliveryOffersState extends State<_CustomerDeliveryOffers>{
  bool loading=true,selecting=false;
  String? error;
  List offers=[];
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{
    try{offers=await Api.instance.get('/orders/${widget.orderId}/offers') as List;error=null;}
    catch(e){error=e.toString();}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> _select(dynamic offer)async{
    setState(()=>selecting=true);
    try{
      await Api.instance.post('/orders/${widget.orderId}/offers/${offer['id']}/select',{});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(dt('تم اختيار السائق وتأكيد الأجرة'))));await widget.onSelected();}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
    finally{if(mounted)setState(()=>selecting=false);}
  }
  @override Widget build(BuildContext context){
    if(loading)return Padding(padding:EdgeInsets.all(12),child:Center(child:CircularProgressIndicator()));
    if(error!=null)return TextButton(onPressed:(){setState(()=>loading=true);_load();},child:Text(dt('تعذر تحميل العروض: $error')));
    if(offers.isEmpty)return Padding(padding:const EdgeInsets.all(12),child:Row(children:[
      Expanded(child:Text(dt('بانتظار عروض السائقين.'))),
      TextButton.icon(onPressed:(){setState(()=>loading=true);_load();},icon:Icon(Icons.refresh),label:Text(dt('تحديث'))),
    ]));
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),child:Row(children:[
        Expanded(child:Text(dt('عروض السائقين'),style:TextStyle(fontWeight:FontWeight.w900))),
        IconButton(onPressed:selecting?null:(){setState(()=>loading=true);_load();},tooltip: dt('تحديث العروض'),icon:Icon(Icons.refresh)),
      ])),
      for(final offer in offers)ListTile(
        leading:CircleAvatar(child:Icon(Icons.delivery_dining)),
        title:Text(offer['driver']?['user']?['name']?.toString()??dt('سائق')),
        subtitle:Text(offer['driver']?['vehicleType']?.toString()??dt('سائق معتمد')),
        trailing:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
          Text('${offer['amount']} ${offer['currency']}',style:TextStyle(fontWeight:FontWeight.w900)),
          TextButton(onPressed:selecting?null:()=>_select(offer),child:Text(dt('اختيار'))),
        ]),
      ),
    ]);
  }
}
