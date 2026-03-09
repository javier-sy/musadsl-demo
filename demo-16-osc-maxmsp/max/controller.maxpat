{
	"patcher" : 	{
		"fileversion" : 1,
		"appversion" : 		{
			"major" : 8,
			"minor" : 6,
			"revision" : 5,
			"architecture" : "x64",
			"modernui" : 1
		}
,
		"classnamespace" : "box",
		"rect" : [ 1549.0, 355.0, 1018.0, 708.0 ],
		"bglocked" : 0,
		"openinpresentation" : 0,
		"default_fontsize" : 12.0,
		"default_fontface" : 0,
		"default_fontname" : "Arial",
		"gridonopen" : 1,
		"gridsize" : [ 15.0, 15.0 ],
		"gridsnaponopen" : 1,
		"objectsnaponopen" : 1,
		"statusbarvisible" : 2,
		"toolbarvisible" : 1,
		"lefttoolbarpinned" : 0,
		"toptoolbarpinned" : 0,
		"righttoolbarpinned" : 0,
		"bottomtoolbarpinned" : 0,
		"toolbars_unpinned_last_save" : 0,
		"tallnewobj" : 0,
		"boxanimatetime" : 200,
		"enablehscroll" : 1,
		"enablevscroll" : 1,
		"devicewidth" : 0.0,
		"description" : "",
		"digest" : "",
		"tags" : "",
		"style" : "",
		"subpatcher_template" : "",
		"assistshowspatchername" : 0,
		"boxes" : [ 			{
				"box" : 				{
					"id" : "obj-20",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 412.0, 270.0, 135.0, 22.0 ],
					"text" : "udpsend localhost 8000"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-19",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 412.0, 153.0, 99.0, 22.0 ],
					"text" : "prepend /register"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-18",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 412.0, 198.0, 89.0, 22.0 ],
					"text" : "prepend /mode"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-17",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 412.0, 108.0, 97.0, 22.0 ],
					"text" : "prepend /density"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-14",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 67.0, 199.0, 60.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 21.0, 156.0, 60.0, 20.0 ],
					"text" : "Mode"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-13",
					"items" : [ "Mayor", ",", "Menor", ",", "Dórico", ",", "Mixolidio" ],
					"maxclass" : "umenu",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "int", "", "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 155.0, 198.0, 100.0, 22.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 109.0, 155.0, 100.0, 22.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-12",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 412.0, 65.0, 80.0, 22.0 ],
					"text" : "prepend /root"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-10",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 67.0, 154.0, 60.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 21.0, 111.0, 60.0, 20.0 ],
					"text" : "Register"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-11",
					"maxclass" : "slider",
					"min" : -2.0,
					"numinlets" : 1,
					"numoutlets" : 1,
					"orientation" : 1,
					"outlettype" : [ "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 155.0, 150.0, 219.0, 28.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 109.0, 107.0, 219.0, 28.0 ],
					"size" : 5.0
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-8",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 67.0, 109.0, 60.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 21.0, 66.0, 60.0, 20.0 ],
					"text" : "Density"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-9",
					"maxclass" : "slider",
					"numinlets" : 1,
					"numoutlets" : 1,
					"orientation" : 1,
					"outlettype" : [ "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 155.0, 105.0, 219.0, 28.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 109.0, 62.0, 219.0, 28.0 ],
					"size" : 8.0
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-7",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 67.0, 66.0, 60.0, 20.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 21.0, 23.0, 60.0, 20.0 ],
					"text" : "Root"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-3",
					"maxclass" : "slider",
					"numinlets" : 1,
					"numoutlets" : 1,
					"orientation" : 1,
					"outlettype" : [ "" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 155.0, 62.0, 219.0, 28.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 109.0, 19.0, 219.0, 28.0 ],
					"size" : 11.0
				}

			}
 ],
		"lines" : [ 			{
				"patchline" : 				{
					"destination" : [ "obj-19", 0 ],
					"midpoints" : [ 164.5, 180.0, 141.0, 180.0, 141.0, 231.0, 399.0, 231.0, 399.0, 147.0, 421.5, 147.0 ],
					"source" : [ "obj-11", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-20", 0 ],
					"midpoints" : [ 421.5, 90.0, 399.0, 90.0, 399.0, 255.0, 421.5, 255.0 ],
					"source" : [ "obj-12", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-18", 0 ],
					"midpoints" : [ 164.5, 231.0, 399.0, 231.0, 399.0, 192.0, 421.5, 192.0 ],
					"source" : [ "obj-13", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-20", 0 ],
					"midpoints" : [ 421.5, 132.0, 399.0, 132.0, 399.0, 255.0, 421.5, 255.0 ],
					"source" : [ "obj-17", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-20", 0 ],
					"midpoints" : [ 421.5, 222.0, 421.5, 222.0 ],
					"source" : [ "obj-18", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-20", 0 ],
					"midpoints" : [ 421.5, 177.0, 399.0, 177.0, 399.0, 255.0, 421.5, 255.0 ],
					"source" : [ "obj-19", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-12", 0 ],
					"midpoints" : [ 164.5, 93.0, 141.0, 93.0, 141.0, 48.0, 421.5, 48.0 ],
					"source" : [ "obj-3", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-17", 0 ],
					"midpoints" : [ 164.5, 135.0, 141.0, 135.0, 141.0, 48.0, 399.0, 48.0, 399.0, 102.0, 421.5, 102.0 ],
					"source" : [ "obj-9", 0 ]
				}

			}
 ],
		"dependency_cache" : [  ],
		"autosave" : 0
	}

}
