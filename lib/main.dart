import 'dart:async';
import 'dart:math' show sin, pi;

import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Smooth Rotation',
			theme: ThemeData(
				primarySwatch: Colors.blue,
				backgroundColor: Colors.grey[300],
				accentColor: Colors.blueAccent[700],
				secondaryHeaderColor: Colors.grey[200],
			),
			home: SmoothRotation(
				child: Scaffold(
					body: SmoothRotationBuilder.rotate(
						child: SmoothRotationBuilder.scale(
							child: SamplePage(),
						),
					),
					floatingActionButton: FloatingActionButton(
						backgroundColor: Colors.red,
						onPressed: () {},
						child: SmoothRotationBuilder.rotate(
							child: Icon(Icons.edit),
						),
					),
				),
			),
		);
	}
}

class SmoothRotation extends StatefulWidget {

	const SmoothRotation({
		Key key,
		@required this.child,
	}) : super(key: key);

	final Widget child;

	static double of(BuildContext context) {
		_SmoothRotationScope scope = context.inheritFromWidgetOfExactType(_SmoothRotationScope);
		return scope?.angle;
	}

	@override
	_SmoothRotationState createState() => _SmoothRotationState();
}

class _SmoothRotationState extends State<SmoothRotation> {

	StreamSubscription<SensorEvent> _sub;
	double _rotationAngle;

	@override
	void initState() {
		super.initState();
		_onPortrait();
		_rotationAngle = 0.0;
		_sub = AeyriumSensor.sensorEvents.listen(_onRotationSensor);
	}

	@override
	void dispose() {
		_sub.cancel();
		super.dispose();
	}

	void _onRotationSensor(SensorEvent event) {
		double newAngle = (-event.roll * 1000).truncate() / 1000.0;
		if ((_rotationAngle - newAngle).abs() > 0.01) {
			setState(() => _rotationAngle = newAngle);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Stack(
			alignment: Alignment.center,
			children: <Widget>[
				_SmoothRotationScope(
					angle: _rotationAngle,
					child: widget.child,
				),
				Align(
					alignment: Alignment.bottomCenter,
					child: Material(
						type: MaterialType.transparency,
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: <Widget>[
								FlatButton(
									onPressed: _onPortrait,
									child: Text('Portrait')
								),
								FlatButton(
									onPressed: _onLandscape,
									child: Text('Landscape')
								),
							],
						),
					),
				),
			],
		);
	}

	void _onPortrait() {
		SystemChrome.setPreferredOrientations([
			DeviceOrientation.portraitUp,
		]);
	}

	void _onLandscape() {
		SystemChrome.setPreferredOrientations([
			DeviceOrientation.landscapeLeft,
		]);
	}
}

class _SmoothRotationScope extends InheritedWidget {
	final double angle;

	const _SmoothRotationScope({
		Key key,
		@required this.angle,
		@required Widget child,
	}) : super(
		key: key,
		child: child,
	);

	@override
	bool updateShouldNotify(_SmoothRotationScope old) => old.angle != angle;
}

typedef Widget RotationBuilder(BuildContext context, Widget child, double angle);

class SmoothRotationBuilder extends StatefulWidget {
	static const _rad90 = 90.0 * pi / 180.0;

	const SmoothRotationBuilder.rotate({
		Key key,
		@required this.child,
	})
		: builder = rotationBuilder,
			super(key: key);

	const SmoothRotationBuilder.scale({
		Key key,
		@required this.child,
	})
		: builder = scaleBuilder,
			super(key: key);

	const SmoothRotationBuilder({
		Key key,
		@required this.builder,
		@required this.child,
	}) : super(key: key);

	final RotationBuilder builder;
	final Widget child;

	@override
	_SmoothRotationBuilderState createState() => _SmoothRotationBuilderState();


	static Widget rotationBuilder(BuildContext context, Widget child, double angle) {
		return Transform.rotate(angle: angle, child: child);
	}

	static Widget scaleBuilder(BuildContext context, Widget child, double angle) {
		final media = MediaQuery.of(context);
		final width = (media.size.width * sin(_rad90 - angle).abs()) +
			(media.size.height * sin(angle).abs());
		final height = (media.size.height * sin(_rad90 - angle).abs()) +
			(media.size.width * sin(angle).abs());
		return OverflowBox(
			minWidth: width,
			maxWidth: width,
			minHeight: height,
			maxHeight: height,
			child: child,
		);
	}
}

class _SmoothRotationBuilderState extends State<SmoothRotationBuilder> {
	@override
	Widget build(BuildContext context) =>
		widget.builder(context, widget.child, SmoothRotation.of(context));
}


class SamplePage extends StatefulWidget {
	@override
	_SamplePageState createState() => _SamplePageState();
}

class _SamplePageState extends State<SamplePage> with SingleTickerProviderStateMixin {
	TabController _tabController;

	@override
	void initState() {
		super.initState();
		_tabController = TabController(length: 5, vsync: this);
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return NestedScrollView(
			headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
				return <Widget>[
					SliverToBoxAdapter(
						child: Column(
							verticalDirection: VerticalDirection.down,
							children: <Widget>[
								Container(
									height: 250.0,
									color: theme.primaryColor,
									child: Center(
										child: FractionallySizedBox(
											widthFactor: 0.5,
											child: Image.asset('assets/logo.png'),
										),
									),
								),
								Container(
									color: theme.backgroundColor,
									child: Column(
										mainAxisSize: MainAxisSize.min,
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: <Widget>[
											Align(
												alignment: Alignment.bottomCenter,
												heightFactor: 0.5,
												child: SmoothRotationBuilder(
													builder: (BuildContext context, Widget child, double angle) {
														final value = ((angle * (180 / pi)) - 90.0) / 180.0;
														//print('angle $angle $value');
														return Align(
															alignment: Alignment(value.abs() - 0.5, 0.0),
															child: child,
														);
													},
													child: Material(
														type: MaterialType.circle,
														color: theme.backgroundColor,
														elevation: 4.0,
														child: CircleAvatar(
															backgroundImage: AssetImage('assets/profile.jpg'),
															radius: 48.0,
														),
													),
												),
											),
											SizedBox(height: 16.0),
											Align(
												alignment: Alignment.bottomCenter,
												child: Text('Miroslav Vitula', style: theme.textTheme.headline),
											),
											Align(
												alignment: Alignment.bottomCenter,
												child: Row(
													mainAxisSize: MainAxisSize.min,
													children: <Widget>[
														Icon(Icons.camera_alt, size: 12.0,),
														SizedBox(width: 6.0),
														Text('Motion designer'),
													],
												),
											),
										],
									),
								),
							],
						),
					),
					SliverAppBar(
						pinned: true,
						floating: true,
						forceElevated: true,
						elevation: 2.0,
						backgroundColor: theme.backgroundColor,
						flexibleSpace: Builder(
							builder: (BuildContext context) {
								final mediaQuery = MediaQuery.of(context);
								final tabMinWidth = mediaQuery.size.shortestSide * 0.25;
								return Padding(
									padding: mediaQuery.padding + const EdgeInsets.only(top: 7.0),
									child: TabBar(
										controller: _tabController,
										labelColor: theme.textTheme.body1.color,
										indicatorColor: theme.primaryColor,
										indicatorWeight: 3.0,
										isScrollable: true,
										tabs: <Widget>[
											_buildTab('ABOUT', tabMinWidth),
											_buildTab('POSTS', tabMinWidth),
											_buildTab('COLLECTIONS', tabMinWidth),
											_buildTab('PHOTOS', tabMinWidth),
											_buildTab('YOUTUBE', tabMinWidth),
										],
									),
								);
							},
						),
					),
				];
			},
			body: MediaQuery.removePadding(
				context: context,
				removeTop: true,
				child: TabBarView(
					controller: _tabController,
					children: <Widget>[
						_buildList(context),
						_buildList(context),
						_buildList(context),
						_buildList(context),
						_buildList(context),
					],
				),
			),
		);
	}

	Widget _buildList(BuildContext context) {
		return Container(
			color: Colors.white,
			child: ListView.builder(
				itemBuilder: (BuildContext context, int index) {
					if (index == 0) {
						return Category(
							icon: Icons.check,
							title: 'Pinned',
						);
					}
					return Post();
				},
			),
		);
	}

	Tab _buildTab(String text, double tabMinWidth) {
		return Tab(
			child: ConstrainedBox(
				constraints: BoxConstraints(
					minWidth: tabMinWidth,
				),
				child: Center(
					child: Text(text),
				),
			),
		);
	}
}

class Category extends StatelessWidget {
	final IconData icon;
	final String title;

	const Category({
		Key key,
		@required this.icon,
		@required this.title,
	}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Container(
			color: theme.secondaryHeaderColor,
			padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
			child: Row(
				children: <Widget>[
					Icon(icon),
					SizedBox(width: 12.0),
					Text(title,
						style: theme.textTheme.body2,
					),
				],
			),
		);
	}
}

class Post extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Padding(
			padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					Row(
						children: <Widget>[
							CircleAvatar(
								backgroundColor: theme.secondaryHeaderColor,
								backgroundImage: AssetImage('assets/profile.jpg'),
								radius: 16.0,
							),
							SizedBox(width: 12.0),
							Text('Miroslav Vitula',
								style: theme.textTheme.body2
									.copyWith(fontSize: 12.0),
							),
							Icon(Icons.chevron_right,
								size: 14.0,
								color: theme.accentColor,
							),
							Text('Material Design',
								style: theme.textTheme.body2.copyWith(
									fontSize: 12.0,
									color: theme.accentColor,
								),
							),
						],
					),
					Padding(
						padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
						child: Text('Some 3D stuff I\'ve been workin on in AE.\nLooking all fresh!'),
					),
					Row(
						children: <Widget>[
							Expanded(
								child: AspectRatio(
									aspectRatio: 1.5,
									child: Container(
										color: Colors.grey[300],
									),
								),
							),
							SizedBox(width: 12.0),
							Expanded(
								child: AspectRatio(
									aspectRatio: 1.5,
									child: Container(
										color: Colors.grey[300],
									),
								),
							),
						],
					),
				],
			),
		);
	}
}
