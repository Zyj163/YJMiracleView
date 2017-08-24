module Fastlane
  module Actions
    module SharedValues
      REMOVE_TAG_CUSTOM_VALUE = :REMOVE_TAG_CUSTOM_VALUE
    end

    class RemoveTagAction < Action
#真正执行的逻辑
      def self.run(params)
		#取出传递的参数
		tag = params[:tag]
		rl = params[:rl]
		rr = params[:rr]
		
		#拼接命令
		cmds = []
		if rl
		cmds << "git tag -d #{tag}"
		end
	
		if rr
		cmds << "git push origin :#{tag}"
		end
		
		UI.message("removing git tag #{tag}")
		
		resultCmd = cmds.join(" & ")
		#执行命令, 接收的是具体命令的字符串
		Actions.sh(resultCmd)
		
      end
#描述
      def self.description
        "remove tag"
      end
  
#详细描述
      def self.details
        "删除本地&远程tag"
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
                                       description: "是否删除本地标签",
									   optional: true,
                                       is_string: false,
                                       default_value: true),
		FastlaneCore::ConfigItem.new(key: :rr,
										description: "是否删除原创标签",
										is_string: false,
										optional: true,
										default_value: true
										)
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
