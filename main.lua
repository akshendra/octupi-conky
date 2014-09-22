require "cairo" -- cairo graphic library

function set_color( num, alpha) 
	
	-- for white color num has no significance
	if color == "WHITE" then
		cairo_set_source_rgba(cr, 1, 1, 1, alpha);
	end

	-- for dark as well color has no significance
	if color == "DARK" then
		cairo_set_source_rgba(cr, 0, 0, 0, alpha);
	end

end

-- the funtion which paints the image in circle
function draw_image (ir,xc, yc, radius, path) 
	local w, h;

	cairo_arc (ir, xc, yc, radius, 0, 2*math.pi);
	cairo_clip (ir);
	cairo_new_path (ir); 


	local image = cairo_image_surface_create_from_png (path);
	w = cairo_image_surface_get_width (image);
	h = cairo_image_surface_get_height (image);


	cairo_scale (ir, 2*radius/w, 2*radius/h);
	w = cairo_image_surface_get_width (image);
	h = cairo_image_surface_get_height (image);

	cairo_set_source_surface (ir, image, xc*(1/(2*radius/w)) - w/2, yc*(1/(2*radius/h)) - h/2);
	cairo_paint (ir);

	cairo_surface_destroy (image);
	cairo_destroy(ir);
end


--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup(  )

	-- opening the settings file for reading the variabes
	local file = io.open("settings");
	local output = file:read("*a");
	io.close(file);
	
	-- reading the variables
	local nex = 0;
	-- dimensions
	_,nex,width = string.find(output,"WIDTH%s*=%s*(.-)%s*;", nex);
	_,nex,height = string.find(output,"HEIGHT%s*=%s*(.-)%s*;", nex);
	-- network
	_,nex,interface = string.find(output, "NETWORK%s*=%s*(.-)%s*;",nex);
	-- cpu
	_,nex,no_of_cores = string.find(output, "NO_OF_CORES%s*=%s*(.-)%s*;",nex);
	-- color style
	_,nex,color = string.find(output, "COLOR%s*=%s*(.-)%s*;",nex);
	-- gmail
	_,nex,mail = string.find(output, "MAIL%s*=%s*(.-)%s*;",nex);
	-- startup variables
	check_mail = 1;
	start = 1;

	-- checking for internet connection
	local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
	internet = tonumber(file:read("*a"));
	io.close(file);

end

function conky_main(  )
	
	-- if no conky window then exit
	if conky_window == nil then return end

	-- the number of update
	local updates = tonumber(conky_parse("${updates}"));
	-- if not third update exit
	if updates < 3 then return end	

	-- prepare cairo drawing surface
	local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height);
	cr = cairo_create(cs);

	-- for text extents
	local extents = cairo_text_extents_t:create();
	local text = "";

	-- few co-ordinates
	local centerx = width/2;
	local centery = height/2;

	-- setup variables for web based content
	local min = tonumber(conky_parse('${time %M}'));
	local sec = tonumber(conky_parse('${time %S}'));
	local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
	internet = tonumber(file:read("*a"));
	io.close(file);	


	-- the centered photo ------------------------------------------- the centered image -------------------------------------------------------

	local face_radius = 50;

	-- image
	local ir = cairo_create(cs);
	draw_image(ir, centerx, centery, face_radius, "face"); 
	
	-- color and other settings for outher boundary
	set_color(1,0.9);
	cairo_set_line_width(cr, 3);
	cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
	cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);

	-- outer boundary
	cairo_arc(cr, centerx , centery, face_radius, 0, 2*math.pi);
	cairo_stroke(cr);


	-- cpu stats ------------------------------------------------------------ cpu ----------------------------------------------------------------------------

	local angle = 10*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- value of cpu
	local cpu = conky_parse("${cpu}");

	-- arrow to cpu
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	if tonumber(cpu) > 25 then
		cairo_set_source_rgba(cr,1,0,0,0.4);
	end
	cairo_fill(cr);

	-- cpu image
	local ir = cairo_create(cs);
	local image_path = "cpu";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	if tonumber(cpu) > 25 then
		cairo_set_source_rgba(cr,1,0,0,1);
	end
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "CPU";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = cpu.."%";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);	


	-- top 10 process ------------------------------------------------ top 10 process cpu -------------------------------------------------------------

	angle = angle - 10*(math.pi/180);
	item_startx = item_centerx + item_radius + 5;	
	item_starty = item_centery;
	item_endx = item_startx + math.cos(angle) * width/6;
	item_endy = item_starty + math.sin(angle) * height/6;
	item_curvex = item_startx + math.cos(angle) * width/12;
	item_curvey = item_starty + math.sin(angle) * height/12;
	-- print(item_startx.." "..item_starty.." "..item_endx.." "..item_endy.." "..item_curvex.." "..item_curvey)

	-- arrow
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- label text
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "Top 10 Process";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_endx - extents.width/2, item_endy + item_font_size+2);
	cairo_show_text(cr, text);

	-- the values
	set_color(1,0.7);
	cairo_select_font_face(cr,"Arial",0,0);
	cairo_set_font_size(cr,item_font_size/1.4);
	for i = 1,10 do
		local addison = "                 ";
		local name = string.sub(conky_parse("${top name "..i.."}")..addison,1,10);
		local value = conky_parse("${top cpu "..i.."}");
		text = name.." "..value;
		cairo_move_to(cr, item_endx - extents.width/2, item_endy + item_font_size/1.2 * (i+1) + 5);
		cairo_show_text(cr,text);
	end


	-- cpu cores ---------------------------------------------- cpu cores ---------------------------------------------------------
	angle = angle + 70*(math.pi/180);
	item_endx = item_startx + math.cos(angle) * width/6;
	item_endy = item_starty + math.sin(angle) * height/6;
	item_curvex = item_startx + math.cos(angle) * width/12;
	item_curvey = item_starty + math.sin(angle) * height/12;
	-- print(item_startx.." "..item_starty.." "..item_endx.." "..item_endy.." "..item_curvex.." "..item_curvey)

	-- arrow
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- label text
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "Cpu Cores";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_endx - extents.width/2, item_endy + item_font_size+2);
	cairo_show_text(cr, text);

	-- the values
	set_color(1,0.7);
	cairo_select_font_face(cr,"Arial",0,0);
	cairo_set_font_size(cr,item_font_size/1.4);
	for i = 1,no_of_cores do
		local name = "CPU "..i;
		local value = conky_parse("${top cpu "..i.."}");
		text = name.."  "..value.."%";
		cairo_move_to(cr, item_endx - extents.width/2, item_endy + item_font_size/1.2 * (i+1) + 5);
		cairo_show_text(cr,text);
	end


	-- swap ------------------------------------------------------------ swap ----------------------------------------------------------------------------

	local angle = 50*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- value of cpu
	local swap = conky_parse("${swapperc}");
	if tonumber(swap) == nil then
		swap = 0;
	end

	-- arrow to swap
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex-100, item_curvey+40, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- swap image
	local ir = cairo_create(cs);
	image_path = "swap";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "SWAP";
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = swap.."%";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);


	-- uptime ------------------------------------------------------------ uptime ----------------------------------------------------------------------------

	local angle = 90*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- value of uptime
	local uptime = conky_parse("${uptime}");

	-- arrow to uptime
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex-100, item_curvey+100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- uptime image
	local ir = cairo_create(cs);
	image_path = "uptime";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "UPTIME";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = uptime;
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);


	-- root file system ------------------------------------------------------------ root fs ----------------------------------------------------------------------------

	local angle = 130*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- value of free space and total space
	local free = "Free: "..conky_parse("${fs_free}");
	local total = "Total: "..conky_parse("${fs_size}");

	-- arrow to root
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey+100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- root drive image
	local ir = cairo_create(cs);
	image_path = "root";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "ROOT";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = free;
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);
	text = total;
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size*2 + 8);
	cairo_show_text(cr, text);


	-- ram  ------------------------------------------------------------ ram ----------------------------------------------------------------------------

	local angle = 210*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- value of ram
	local ram = conky_parse("${memperc}");

	-- arrow to ram
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-70, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- root drive image
	local ir = cairo_create(cs);
	image_path = "ram";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "RAM";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = ram.."%";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);


	-- top 10 process ------------------------------------------------ top 10 process ram -------------------------------------------------------------

	angle = angle + 20*(math.pi/180);
	item_startx = item_centerx - item_radius - 5;	
	item_starty = item_centery;
	item_endx = item_startx + math.cos(angle) * width/6;
	item_endy = item_starty + math.sin(angle) * height/6;
	item_curvex = item_startx + math.cos(angle) * width/12;
	item_curvey = item_starty + math.sin(angle) * height/12;
	-- print(item_startx.." "..item_starty.." "..item_endx.." "..item_endy.." "..item_curvex.." "..item_curvey)

	-- arrow
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- label text
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "Top 10 Process";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_endx - extents.width/2, item_endy + item_font_size+2);
	cairo_show_text(cr, text);

	-- the values
	set_color(1,0.7);
	cairo_select_font_face(cr,"Arial",0,0);
	cairo_set_font_size(cr,item_font_size/1.4);
	for i = 1,10 do
		local addison = "                 ";
		local name = string.sub(conky_parse("${top_mem name "..i.."}")..addison,1,10);
		local value = conky_parse("${top_mem mem_res "..i.."}");
		text = name.." "..value;
		cairo_move_to(cr, item_endx - extents.width/2, item_endy + item_font_size/1.2 * (i+1) + 5);
		cairo_show_text(cr,text);
	end


	-- disk input output  ------------------------------------------------------------ disk io ----------------------------------------------------------------------------

	local angle = 170*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- value of disk io
	local diskio = conky_parse("${diskio}");

	-- arrow to disk io
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-40, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- root drive image
	local ir = cairo_create(cs);
	image_path = "root";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "DISK I/O";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = diskio;
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);


	-- disk read write ------------------------------------------------ read write -------------------------------------------------------------

	angle = angle + 10*(math.pi/180);
	item_startx = item_centerx - item_radius - 5;	
	item_starty = item_centery;
	item_endx = item_startx + math.cos(angle) * width/6;
	item_endy = item_starty + math.sin(angle) * height/6;
	item_curvex = item_startx + math.cos(angle) * width/12;
	item_curvey = item_starty + math.sin(angle) * height/12;
	-- print(item_startx.." "..item_starty.." "..item_endx.." "..item_endy.." "..item_curvex.." "..item_curvey)

	-- arrow
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-50, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- label text
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- read
	text = "Read: "..conky_parse("${diskio_read}");
	cairo_text_extents(cr,text,extents);
	cairo_move_to(cr, item_endx - extents.width/2, item_endy+item_font_size+2);
	cairo_show_text(cr,text);

	-- write
	text = "Write: "..conky_parse("${diskio_write}");
	cairo_text_extents(cr,text,extents);
	cairo_move_to(cr, item_endx - extents.width/2, item_endy+item_font_size*2+2);
	cairo_show_text(cr,text);

		-- battery --------------------------------------------------- battery --------------------------------------------------------------------
	local angle = 250*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- arrow to mail
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex+50, item_curvey-70, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- image
	local ir = cairo_create(cs);
	image_path = "battery";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "Power";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = conky_parse("${battery_short}");
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);


	-- time and date ------------------------------------------ time and date
	
	local hour = conky_parse('${time %I}');
	local minute = conky_parse('${time %M}');
	local part = conky_parse('${time %p}');
	local day = conky_parse('${time %d}');
	local month = conky_parse('${time %B}');
	local year = conky_parse('${time %G}');

	-- time
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0,1);
	cairo_set_font_size(cr,height/10);
	text = hour..":"..minute..part;
	cairo_text_extents(cr,text,extents)
	cairo_move_to(cr, centerx - extents.width/2,  height/6);
	cairo_show_text(cr, text);
	local time_height = height/6;

	-- date
	set_color(1,0.6);
	item_font_size = height/30;
	cairo_select_font_face(cr, "Arial",0,0);
	cairo_set_font_size(cr, item_font_size)
	text = month.." "..day..", "..year;
	cairo_text_extents(cr,text,extents)
	cairo_move_to(cr, centerx - extents.width/2,  time_height + height/30);
	cairo_show_text(cr, text);


	-- network ----------------------------------------------------------------------- network -------------------------------------------------------------------------

	local angle = 320*math.pi/180;
	local item_startx = centerx + math.cos(angle) * face_radius;
	local item_starty = centery + math.sin(angle) * face_radius;
	local item_endx = centerx + math.cos(angle) * width/6;
	local item_endy = centery + math.sin(angle) * height/6;
	local item_curvex = centerx + math.cos(angle) * width/12;
	local item_curvey = centery + math.sin(angle) * height/12;
	local item_radius = 15;
	local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	local item_font_size = height/50;

	-- ip address
	local network = conky_parse("${addr "..interface.."}");

	-- arrow to network
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-70, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	-- background circle
	cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	set_color(1,0.4);
	cairo_fill(cr);

	-- image
	local ir = cairo_create(cs);
	image_path = "network";
	if color == "WHITE" then
		image_path = "white/"..image_path
	end
	if color == "DARK" then
		image_path = "dark/"..image_path
	end
	draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- outside boundry
	cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	set_color(1,1);
	cairo_stroke(cr);

	-- font settings
	set_color(1,1);
	cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	cairo_set_font_size(cr, item_font_size);

	-- name text
	text = "I.P.";
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	cairo_show_text(cr, text);

	-- value text
	text = network;
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	cairo_show_text(cr, text);


	-- network stats ------------------------------------------------ network stats -------------------------------------------------------------

	angle = angle - 10*(math.pi/180);
	item_startx = item_centerx + item_radius + 5;	
	item_starty = item_centery;
	item_endx = item_startx + math.cos(angle) * width/6;
	item_endy = item_starty + math.sin(angle) * height/6;
	item_curvex = item_startx + math.cos(angle) * width/12;
	item_curvey = item_starty + math.sin(angle) * height/12;
	-- print(item_startx.." "..item_starty.." "..item_endx.." "..item_endy.." "..item_curvex.." "..item_curvey)

	-- arrow
	cairo_move_to(cr, item_startx, item_starty);
	cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-100, item_endx, item_endy);
	set_color(1,0.5);
	cairo_stroke(cr);

	set_color(1,1);
	cairo_move_to(cr,item_endx,item_endy+item_font_size+5);
	cairo_show_text(cr,"Upload");
	cairo_move_to(cr,item_endx + width/13,item_endy+item_font_size+5);
	cairo_show_text(cr,"Download");
	cairo_move_to(cr,item_endx - width/20,item_endy+item_font_size*2+5);
	cairo_show_text(cr, "Now");	
	
	cairo_select_font_face(cr,"Arial",0,0)
	cairo_set_font_size(cr,item_font_size/1.4);
	set_color(1,0.6);
	text = conky_parse("${upspeed "..interface.."}");
	cairo_move_to(cr,item_endx  ,item_endy+item_font_size*2+5);
	cairo_show_text(cr, text);
	text = conky_parse("${downspeed "..interface.."}");
	cairo_move_to(cr,item_endx + width/13,item_endy+item_font_size*2+5);
	cairo_show_text(cr, text);	

	local month = conky_parse("${time %b}");
	local year = conky_parse("${time %y}");
	local stats = conky_parse("${exec vnstat -i "..interface.."}");
	local ntotal_recieved, ntotal_trans, nmonth_received, nmonth_trans, ntoday_rec, ntoday_trans;
	-- print(stats);
	if(stats ~= "") then
		_,nex,ntotal_recieved = string.find(stats, "rx:%s*(.-)iB");
		if(ntotal_recieved ~= nil ) then
			total_recieved = ntotal_recieved;
		end
		-- print("tr: "..total_recieved.."iB");
		_,nex,ntotal_trans = string.find(stats, "tx:%s*(.-)iB",nex);
		if(ntotal_trans ~= nil) then
			total_trans = ntotal_trans;
		end
		-- print("tt: "..total_trans..'iB');

		_,nex,_ = string.find(stats, "monthly",nex);

		_,nex,nmonth_received = string.find(stats, month.."%s*\'"..year.."%s*(.-)iB",nex);
		if(nmonth_received ~= nil) then
			month_recieved = nmonth_received;
		end
		-- print("mr: "..month_recieved..'iB');

		_,nex,nmonth_trans = string.find(stats, "|%s*(.-)iB",nex);
		if(nmonth_trans ~= nil) then
			month_trans = nmonth_trans;
		end
		-- print("mt: "..month_trans..'iB');

		_,nex,ntoday_rec = string.find(stats, "today%s*(.-)iB",nex);
		if(ntoday_rec ~= nil) then
			today_rec = ntoday_rec;
		end
		-- print("tor: "..today_rec..'iB');

		_,nex,ntoday_trans = string.find(stats, "|%s*(.-)iB",nex);
		if(ntoday_trans ~= nil) then
			today_trans = ntoday_trans;
		end
		-- print("tot: "..today_trans..'iB');

		cairo_set_font_size(cr, item_font_size);
		cairo_select_font_face(cr, "Familian Elder",0,1);
		set_color(1,1);
		cairo_move_to(cr,item_endx-width/20 ,item_endy+item_font_size*3+5);
		cairo_show_text(cr,"Today");
		cairo_move_to(cr,item_endx-width/20 ,item_endy+item_font_size*4+5);
		cairo_show_text(cr,"Month");
		cairo_move_to(cr,200,220);
		cairo_move_to(cr,item_endx-width/20 ,item_endy+item_font_size*5+5);
		cairo_show_text(cr,"Total");

		cairo_select_font_face(cr,"Arial",0,0)
		cairo_set_font_size(cr,item_font_size/1.4);
		set_color(1,0.6);
		cairo_move_to(cr,item_endx ,item_endy+item_font_size*3+5);
		cairo_show_text(cr,today_trans.."iB");
		cairo_move_to(cr,item_endx ,item_endy+item_font_size*4+5);
		cairo_show_text(cr,month_trans.."iB");
		cairo_move_to(cr,item_endx ,item_endy+item_font_size*5+5);
		cairo_show_text(cr,total_trans.."iB");


		cairo_move_to(cr,item_endx + width/13 ,item_endy+item_font_size*3+5);
		cairo_show_text(cr, today_rec.."iB");
		cairo_move_to(cr,item_endx + width/13 ,item_endy+item_font_size*4+5);
		cairo_show_text(cr,month_recieved.."iB");
		cairo_move_to(cr,item_endx + width/13 ,item_endy+item_font_size*5+5);
		cairo_show_text(cr,total_recieved.."iB");
	end


	-- gmail --------------------------------------------------------------- gmail new message -------------------------------------------------------------

	-- if (min*60 + sec)%298 == 0 then
	-- 	check_mail = 1;
	-- end

	-- if (min%5 == 0 and check_mail == 1) or start == 1 then
	-- if internet == 1 then
	-- 		local val = conky_parse("${execi 300 curl -u "..mail.."}");
	-- 		_,_,new_mail = string.find(val, "<fullcount>%s*(.-)%s*</fullcount>");	
	-- 	end
	-- 	check_mail = 0;
	-- 	start = 0;
	-- end

	-- if internet ~= 1 then
	-- 	new_mail = "No Network"
	-- end

	-- if new_mail == nil then
	-- 	new_mail = "Error!"
	-- end

	-- local angle = 290*math.pi/180;
	-- local item_startx = centerx + math.cos(angle) * face_radius;
	-- local item_starty = centery + math.sin(angle) * face_radius;
	-- local item_endx = centerx + math.cos(angle) * width/6;
	-- local item_endy = centery + math.sin(angle) * height/6;
	-- local item_curvex = centerx + math.cos(angle) * width/12;
	-- local item_curvey = centery + math.sin(angle) * height/12;
	-- local item_radius = 15;
	-- local item_centerx = item_endx + math.cos(angle) * (item_radius + 5);
	-- local item_centery = item_endy + math.sin(angle) * (item_radius + 5);
	-- local item_font_size = height/50;

	-- -- arrow to mail
	-- cairo_move_to(cr, item_startx, item_starty);
	-- cairo_curve_to(cr, item_curvex, item_curvey, item_curvex, item_curvey-70, item_endx, item_endy);
	-- set_color(1,0.5);
	-- cairo_stroke(cr);

	-- -- background circle
	-- cairo_arc(cr, item_centerx, item_centery, item_radius+5,  0, 2*math.pi );
	-- set_color(1,0.4);
	-- cairo_fill(cr);

	-- -- image
	-- local ir = cairo_create(cs);
	-- image_path = "mail";
	-- if color == "WHITE" then
	-- 	image_path = "white/"..image_path
	-- end
	-- if color == "DARK" then
	-- 	image_path = "dark/"..image_path
	-- end
	-- draw_image(ir, item_centerx, item_centery, item_radius, image_path);

	-- -- outside boundry
	-- cairo_arc(cr, item_centerx, item_centery, item_radius + 5,  0, 2*math.pi );
	-- set_color(1,1);
	-- cairo_stroke(cr);

	-- -- font settings
	-- set_color(1,1);
	-- cairo_select_font_face(cr, "Familian Elder", 0 , 1);
	-- cairo_set_font_size(cr, item_font_size);

	-- -- name text
	-- text = "Unread";
	-- cairo_text_extents(cr, text, extents)
	-- cairo_move_to(cr, item_centerx - extents.width/2, item_centery - item_radius - 10);
	-- cairo_show_text(cr, text);

	-- -- value text
	-- text = new_mail;
	-- cairo_text_extents(cr, text, extents)
	-- cairo_move_to(cr, item_centerx - extents.width/2, item_centery + item_radius + item_font_size + 8);
	-- cairo_show_text(cr, text);


	-- destroying the cairo surface
	cairo_destroy(cr);
	cairo_surface_destroy(cs);
	cr=nil;
end