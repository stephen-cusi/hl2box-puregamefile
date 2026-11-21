
var IS_SPAWN_MENU = false;

var App = angular.module( 'MenuApp', [ 'ngRoute', 'ngLocalize' ] );

// Workshop preview files are written by HL2SB's native cache. Angular treats
// the menu's asset:// scheme as unsafe, so set only this specific image path.
App.directive( 'hl2sbWorkshopPreview', function()
{
	return function( scope, element, attrs )
	{
		var image = element[ 0 ];
		if ( image.tagName !== 'IMG' ) return;

		scope.$watch( attrs.hl2sbWorkshopPreview, function( path )
		{
			var match = typeof path === 'string' && /^(\.cache\/workshop\/([1-9][0-9]{0,19})\/preview\.(?:png|jpg))$/.exec( path );
			if ( !match || match[ 1 ] !== path || ( match[ 2 ].length === 20 && match[ 2 ] > '18446744073709551615' ) )
			{
				image.removeAttribute( 'src' );
				return;
			}
			image.setAttribute( 'src', 'asset://garrysmod/' + path );
		} );
	};
} );

App.config( function( $routeProvider, $compileProvider, $locationProvider, $controllerProvider )
{
	$routeProvider.when('/', { templateUrl: 'template/main.html' } );
	$routeProvider.when('/addons/', { templateUrl: 'template/addon_list.html' } );
	$routeProvider.when('/newgame/', { templateUrl: 'template/newgame.html' } );
	$routeProvider.when('/servers/', { templateUrl: 'template/servers.html' } );
	$routeProvider.when('/demos/', { templateUrl: 'template/demos.html' } );
	$routeProvider.when('/saves/', { templateUrl: 'template/saves.html' } );
	$routeProvider.when('/dupes/', { templateUrl: 'template/dupes.html' } );

	$controllerProvider.register( 'MenuController', MenuController );
	$controllerProvider.register( 'ControllerMain', ControllerMain );
	$controllerProvider.register( 'ControllerNewGame', ControllerNewGame );
	$controllerProvider.register( 'ControllerServers', ControllerServers );
	$controllerProvider.register( 'ControllerAddons', ControllerAddons );
	$controllerProvider.register( 'ControllerDupes', ControllerDupes );
	$controllerProvider.register( 'ControllerSaves', ControllerSaves );
	$controllerProvider.register( 'ControllerDemos', ControllerDemos );
} );
