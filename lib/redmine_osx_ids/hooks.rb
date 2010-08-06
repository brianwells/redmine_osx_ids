module RedmineOsxIds
    class Hooks < Redmine::Hook::ViewListener
       
        def view_layouts_base_html_head(context={})
        
            image_path = File.join(RAILS_ROOT,"/public/plugin_assets/redmine_osx_ids/images/network.png")
            unless File.exists? image_path
                # generate network icon image
                require 'ftools'
                File.makedirs File.dirname(image_path)
                require 'osx/cocoa'
                image = OSX::NSImage.imageNamed(OSX::NSImageNameNetwork).copy
                image.setScalesWhenResized true
                image.setSize OSX::NSMakeSize(16, 16)
                newimg = OSX::NSImage.alloc.initWithSize(OSX::NSMakeSize(16,16))
                newimg.lockFocus
                image.compositeToPoint_operation(OSX::NSZeroPoint, OSX::NSCompositeSourceOver)
                newimg.unlockFocus
                rep = OSX::NSBitmapImageRep.alloc.initWithData(newimg.TIFFRepresentation)
                png = rep.representationUsingType_properties(OSX::NSPNGFileType,nil)
                png.writeToFile_atomically(image_path,true)
            end
            
            return stylesheet_link_tag("#{Redmine::Utils.relative_url_root}/plugin_assets/redmine_osx_ids/stylesheets/redmine_osx_ids.css")
        end
    end
end