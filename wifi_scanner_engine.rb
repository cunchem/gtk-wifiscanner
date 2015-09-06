#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'gtk3'
require './device'
require 'time'
require "stringio"
require 'timeout'



GRAPHIC_DIR="Graphic"
LOGO_INRIA= GRAPHIC_DIR +  "/logo-inria.jpg"
LOGO_PRIVATICS= GRAPHIC_DIR + "/logo-privatics.png"
LOGO_INSA= GRAPHIC_DIR +  "/Logo_INSA_Lyon_2014.png"
LOGO_CITI= GRAPHIC_DIR +  "/Citi_small.png"
LOGO_SCANNER= GRAPHIC_DIR + "/logo-scanner.png"



TIMEOUT = 61
DEVICES = Hash.new()
PERIOD = 1
def format_ss(ss)
 # return "#{100+ ss.to_i}%  (#{ss} dB)"
  x =  (100+ss.to_i)
  puts x
  x = x.to_s
  puts x
  x = x.to_s.rjust(2, "0")
  puts x
  return "#{x}%"

  return "#{100+ ss.to_i}%"

end 
def insert_ssid(dev,ssid)
  if(ssid == "") then 
    return
  end
  found = false
  TREESTORE.each do |model,path,iter|
    (iter[5] == dev.mac && iter[4] == ssid) and found = true 
  end
  if(!found) then 
    iter = TREESTORE.iter_first
    
    begin
      #puts "#{iter}"
    end while iter.next! && iter[0]!=dev.mac
    iter[3] = dev.nbssids
    iter[2] = format_ss(dev.ss) #dev.ss 
    child = TREESTORE.append(iter)
    child[4] = ssid
    child[5] = dev.mac
  end
end

def update_treestore(dev,ssid)
  found = false
  TREESTORE.each do |model,path,iter|
    (iter[0] == dev.mac ) and found = true 
  end
  if(found) then 
    insert_ssid(dev,ssid)
    
  else
    parent = TREESTORE.append(nil)
    parent[0] = dev.mac
    parent[1] = dev.vendor
    parent[2] = format_ss(dev.ss) #dev.ss
    parent[3] = dev.nbssids
    
    dev.ssids.each do |ssid|
      insert_ssid(dev,ssid)
    end
  end
end
def remove_from_treestore(mac)
  to_remove = []
  TREESTORE.each do |model,path,iter|
    (iter[0] == mac ) and to_remove.push(Gtk::TreeRowReference.new(model,path))
  end
  
  to_remove.each do |rowref|
    (path = rowref.path) and TREESTORE.remove(TREESTORE.get_iter(path))
  end


end

def parse_line(line)
  array = line.split(';')
  time = Time.parse(array[0])
  sa = array[1]
  da= array[2]
  ss = array[3]
  ssid = array[4].chomp
  if(ss == '') then 
    ss = 0
  end
  return  time, sa, da, ss, ssid
end
def update_device(sa,time,da,ss,ssid)
  
  dev = DEVICES[sa]
  puts dev
  if(dev==nil ) then
    dev = Device.new(time, sa, da, ss, ssid)
    DEVICES[sa]=dev
  else
    dev.update(time,ss,ssid)
  end 
  puts dev
  update_treestore(dev,ssid)
 
  #DEVICES=DEVICES.sort{|x,y| x[3]<=>y[3]}
  #dev.display()
end

def clean_device_list()
  t_n = Time.now
  #DEVICES.delete_if {|k,v| t_n - v.get_time > TIMEOUT}
  DEVICES.each do |k,v|
    if( t_n - v.get_time > TIMEOUT) then
      remove_from_treestore(v.mac)
      DEVICES.delete(k)
    end
  end
  
end
def update_summary_info()
  text = "<big> \n  Nombre d'appareils: #{DEVICES.size} </big>"
  #text =  "<big> \n  Number of visible devices: #{DEVICES.size} </big>"
  SUMMARY_INFO.set_markup(text)
  

end
def update_device_list(line)
  time, sa, da, ss, ssid = parse_line(line)
  update_device(sa,time,da,ss,ssid)
  clean_device_list()
  update_summary_info()
  
end



TREESTORE = Gtk::TreeStore.new(String, String, String,Integer,String, String)
treestore = TREESTORE

scrolled_window = Gtk::ScrolledWindow.new( nil, nil )
scrolled_window.border_width=( 10 )
scrolled_window.set_policy( Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS )


view = Gtk::TreeView.new(treestore)
view.selection.mode = Gtk::SELECTION_NONE

def new_treeview_column(name, column_id)
  renderer = Gtk::CellRendererText.new()
  col = Gtk::TreeViewColumn.new(name,
                                renderer,
                                :text => column_id)
  col.clickable = true
  col.sort_column_id = column_id
  return col
end

# Create a renderer
view.append_column(new_treeview_column("Identifier", 0))
view.append_column(new_treeview_column("Vendor", 1))
view.append_column(new_treeview_column("Signal", 2))
view.append_column(new_treeview_column("Nb. networks", 3))
view.append_column(new_treeview_column("Networks", 4))



vbox = Gtk::VBox.new(homogeneous=false, spacing=nil)
hbox = Gtk::HBox.new(homogeneous=false, spacing=nil)
hbox.set_spacing(15)

title = Gtk::Label.new
title.set_markup(" ")
vbox.pack_start(title, expand = false, padding = 10)

# Add the logo to the header


#logo_insa = Gtk::Image.new(LOGO_INSA)
#hbox.pack_start(logo_insa, expand = true, padding = 10)

#logo_citi = Gtk::Image.new(LOGO_CITI)
#hbox.pack_start(logo_citi, expand = true, padding = 10)

logo_inria = Gtk::Image.new(LOGO_INRIA)
hbox.pack_start(logo_inria, expand = true, padding = 10)

image_wifi = Gtk::Image.new(LOGO_SCANNER)
hbox.pack_start(image_wifi, expand = true, padding = 10)


logo_privatics = Gtk::Image.new(LOGO_PRIVATICS)
hbox.pack_start(logo_privatics, expand = true, padding = 10)

vbox.pack_start(hbox, expand = false, padding = 10)

SUMMARY_INFO = Gtk::Label.new
SUMMARY_INFO.set_markup("<big>\n  Nombre d'appareils visibles: 0</big>")
#vbox.pack_start_defaults(view)
hbox_summary = Gtk::HBox.new(homogeneous=false, spacing=nil) 

hbox_summary.pack_start(SUMMARY_INFO, expand = false, padding = 10)
vbox.pack_start(hbox_summary, expand = false, padding = 10)



vbox.pack_start(scrolled_window,expand = true, fill = true, padding = 0)
scrolled_window.add_with_viewport( view )


window = Gtk::Window.new("Wi-Fi Probe request informations")

window.set_size_request( 900, 500 )

window.signal_connect("destroy") { Gtk.main_quit }
window.add(vbox)
window.show_all
Gtk.idle_add{
  begin
    status = Timeout::timeout(0.2) {
 
      
      line = ARGF.gets 
      puts line
      begin 
      update_device_list(line)
      rescue 
        
      end
    }
  rescue Timeout::Error => e
    @error = e
    #puts "Timeout reached"
    #render :action => "error"
  end
; true
}

Gtk.main

