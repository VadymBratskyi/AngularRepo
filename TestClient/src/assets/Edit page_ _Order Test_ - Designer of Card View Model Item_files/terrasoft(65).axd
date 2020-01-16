Terrasoft.JSHintConfig = Terrasoft.JSHintConfig || {};
Terrasoft.JSHintConfig.options = {
	// Enforcing options
	"bitwise": true,
	"camelcase": true,
	"curly": true,
	"eqeqeq": true,
	"forin": false,
	"freeze": true, // new
	"immed": true,
	"indent": 1,
	"latedef": true,
	"newcap": true,
	"noarg": true,
	"noempty": true,
	"nonbsp": true, //new
	"nonew": true,
	"plusplus": false,
	"quotmark": "double",
//	"regexp": true, // obsolete
	"undef": true,
	"unused": "vars", // can be set to 'vars' or 'strict'
	"strict": false,
	"trailing": true,
	"maxdepth": 0,
	"maxstatements": 0,
	"maxcomplexity": 0,
	"maxlen": 120,

	// Relaxing options
	"asi": false,
	"boss": false,
	"debug": false,
	"eqnull": true,
	"esversion": 6,
	"evil": false,
	"expr": false,
	"funcscope": false,
	"gcl": false, // new
	"globalstrict": false,
	"iterator": false,
	"lastsemic": false,
	"laxbreak": true,
	"laxcomma": false,
	"loopfunc": false,
	"maxerr": 500,
	"moz": false, // new
	"multistr": false,
	"notypeof": false, // new
//	"onecase": false, // obsolete
	"proto": false,
//	"regexdash": true, // obsolete
	"scripturl": false,
	"smarttabs": false,
	"shadow": false,
	"sub": false,
	"supernew": false,
	"validthis": false,

	"browser": true,
	"devel": false,
	"jquery": true,
	"nonstandard": false,

	// Legacy options
//	"nomen": false, // obsolete
//	"onevar": false, //obsolete
//	"passfail": false, // obsolete
	"white": true,

	// Globals
	"globals": {
		"define": false,
		"Ext": false,
		"Siesta": false,
		"Terrasoft": true,
		"_": false,
		"Backbone": false,
		"StartTest": false,
		"startTest": false,
		"require": false,
		"requirejs": false,
		"coreModules": true,
		"FileAPI": false
	}
};
