module Fastlane
  module Actions
    module SharedValues
      WRITE_TAG_CUSTOM_VALUE = :WRITE_TAG_CUSTOM_VALUE
    end

    class WriteTagAction < Action
#真正执行的逻辑
      def self.run(params)
		#取出传递的参数
		tag = params[:tag]
		rl = params[:rl]
		
		if !rl
		rl = Dir.glob('*.podspec')[0]
		end
		
		str=""
		File.open(rl,'r'){|f|
			f.each_line{|l|
			ss=l.gsub!(/s.version\s*=/,"#")
				if ss
				UI.message("write tag #{tag} to #{rl}")
				str+="  s.version          = '#{tag}'\n"
				else
				str+=l
				end
			}
		}
		file=File.new(rl, 'w')
		file.write str
		file.close
	
      end
#描述
      def self.description
        "write tag"
      end
  
#详细描述
      def self.details
        "修改podspecs中version"
      end

#参数
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :tag,
                                       description: "tag name",
									   is_string: true,
									   optional: false
									   ),
          FastlaneCore::ConfigItem.new(key: :rl,
                                       description: "podspecs文件路径",
									   optional: true,
                                       is_string: true)
        ]
      end
#输出
      def self.output
        ""
      end
#返回值
      def self.return_value
		nil
      end
#作者
      def self.authors
        ["Zyj163"]
      end
#支持的平台
      def self.is_supported?(platform)
        [:ios, :mac].include? platform
      end
    end
  end
end
