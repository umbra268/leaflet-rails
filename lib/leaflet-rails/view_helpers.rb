require 'active_support/inflector'
module Leaflet
  module ViewHelpers

    def map(options)

      options[:base_maps] ||= Leaflet.base_maps
      options[:overlay_maps] ||= Leaflet.overlay_maps
      # options[:tile_layer] ||= Leaflet.tile_layer
      # options[:attribution] ||= Leaflet.attribution
      # options[:max_zoom] ||= Leaflet.max_zoom
      # options[:subdomains] ||= Leaflet.subdomains
      options[:container_id] ||= 'map'

      # tile_layer = options.delete(:tile_layer) || Leaflet.tile_layer
      # attribution = options.delete(:attribution) || Leaflet.attribution
      # max_zoom = options.delete(:max_zoom) || Leaflet.max_zoom
      container_id = options.delete(:container_id) || 'map'
      no_container = options.delete(:no_container)
      center = options.delete(:center)
      markers = options.delete(:markers)
      circles = options.delete(:circles)
      polylines = options.delete(:polylines)
      fitbounds = options.delete(:fitbounds)

      base_maps = options.delete(:base_maps)
      overlay_maps = options.delete(:overlay_maps)


      output = []
      output << "<div id='#{container_id}' style='height: 100%;'></div>" unless no_container
      output << "<script>"

      base_maps.each_with_index do |layer,index|
        #each layer should have a url
        _output = "var base_map#{index} = L.tileLayer('layer[:url]',{"
        #each layer might have max_zoom & subdomians & attribution
        if layer[:attrib]
          _output << "attribution: '#{layer[:attrib]}'"
          if layer[:max_zoom] || layer[:subdomains]
            _output << ","
          end
        end
        if layer[:max_zoom]
          _output << "maxZoom: '#{layer[:max_zoom]}'"
          if layer[:subdomains]
            _output << ","
          end
        end
        if layer[:subdomains]
          _output << "subdomains: #{layer[:subdomains]}'"
        end
        _output << "});"
        output << _output+'\n'
      end
      output << "var basemaps = {"
      base_maps.each_with_index do |layer,index|
        #each layer should have a url
        output << '"#{layer[:name]}": base_map#{index}'
        if(index!=base_maps.length-1) 
          output << ","
        end
        output << '\n'
      end
      output << '};\n\n'
      overlay_maps.each_with_index do |layer,index|
        #each layer should have a url
        _output = "var overlay_map#{index} = L.tileLayer('layer[:url]',{"
        #each layer might have max_zoom & subdomians & attribution
        if layer[:attrib]
          _output << "attribution: '#{layer[:attrib]}'"
          if layer[:max_zoom] || layer[:subdomains]
            _output << ","
          end
        end
        if layer[:max_zoom]
          _output << "maxZoom: '#{layer[:max_zoom]}'"
          if layer[:subdomains]
            _output << ","
          end
        end
        if layer[:subdomains]
          _output << "subdomains: #{layer[:subdomains]}'"
        end
        _output << "});"
        output << _output+'\n'
      end
      output << "var overlaymaps = {"
      base_maps.each_with_index do |layer,index|
        #each layer should have a url
        output << '"#{layer[:name]}": overlay_map#{index}'
        if(index!=overlay_maps.length-1)
          output << ","
        end
        output << '\n'
      end
      output << '};\n\n'

      output << "var map = L.map('#{container_id}')"
      output << "base_map0.addTo(map);"
      output << "L.control.layers(basemaps, overlaymaps).addTo(map);"

      if center
        output << "map.setView([#{center[:latlng][0]}, #{center[:latlng][1]}], #{center[:zoom]})"
      end

      if markers
        markers.each_with_index do |marker, index|
          if marker[:icon]
            icon_settings = prep_icon_settings(marker[:icon])
            output << "var #{icon_settings[:name]}#{index} = L.icon({iconUrl: '#{icon_settings[:icon_url]}', shadowUrl: '#{icon_settings[:shadow_url]}', iconSize: #{icon_settings[:icon_size]}, shadowSize: #{icon_settings[:shadow_size]}, iconAnchor: #{icon_settings[:icon_anchor]}, shadowAnchor: #{icon_settings[:shadow_anchor]}, popupAnchor: #{icon_settings[:popup_anchor]}})"
            output << "marker = L.marker([#{marker[:latlng][0]}, #{marker[:latlng][1]}], {icon: #{icon_settings[:name]}#{index}}).addTo(map)"
          else
            output << "marker = L.marker([#{marker[:latlng][0]}, #{marker[:latlng][1]}]).addTo(map)"
          end
          if marker[:popup]
            output << "marker.bindPopup('#{marker[:popup]}')"
          end
        end
      end

      if circles
        circles.each do |circle|
          output << "L.circle(['#{circle[:latlng][0]}', '#{circle[:latlng][1]}'], #{circle[:radius]}, {
           color: '#{circle[:color]}',
           fillColor: '#{circle[:fillColor]}',
           fillOpacity: #{circle[:fillOpacity]}
        }).addTo(map);"
        end
      end

      if polylines
        polylines.each do |polyline|
          _output = "L.polyline(#{polyline[:latlngs]}"
          _output << "," + polyline[:options].to_json if polyline[:options]
          _output << ").addTo(map);"
          output << _output.gsub(/\n/,'')
        end
      end

      if fitbounds
        output << "map.fitBounds(L.latLngBounds(#{fitbounds}));"
      end

      # if tile_layers
      #   tile_layers.each do |tile_layer|
      #     _output = "L.tileLayer('#{tile_layer[:url]}', {
      #     attribution: '#{tile_layer[:attrib]}',
      #     maxZoom: #{tile_layer[:max_zoom]}"
      #     if tile_layer[:subdomains]
      #       _output << ",
      #       subdomains: #{tile_layer[:subdomains]}"
      #     end
      #     _output << "}).addTo(map)"
      #     output << _output#.gsub(/\n/,'')
      #   end
      # end

      # output << "L.tileLayer('#{tile_layer}', {
      #     attribution: '#{attribution}',
      #     maxZoom: #{max_zoom},"

      # if options[:subdomains]
      #   output << "    subdomains: #{options[:subdomains]},"
      #   options.delete( :subdomains )
      # end

      # options.each do |key, value|
      #   output << "#{key.to_s.camelize(:lower)}: '#{value}',"
      # end
      # output << "}).addTo(map)"

      output << "</script>"
      output.join("\n").html_safe
    end

    private

    def prep_icon_settings(settings)
      settings[:name] = 'icon' if settings[:name].nil? or settings[:name].blank?
      settings[:shadow_url] = '' if settings[:shadow_url].nil?
      settings[:icon_size] = [] if settings[:icon_size].nil?
      settings[:shadow_size] = [] if settings[:shadow_size].nil?
      settings[:icon_anchor] = [0, 0] if settings[:icon_anchor].nil?
      settings[:shadow_anchor] = [0, 0] if settings[:shadow_anchor].nil?
      settings[:popup_anchor] = [0, 0] if settings[:popup_anchor].nil?
      return settings
    end
  end

end
