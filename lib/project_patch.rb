require_dependency 'project'

# Patches Redmine's Project dynamically.
module ProjectPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      has_one :cosmosys_project
      after_validation :validate_csreportmetadata
    end

  end

  module ClassMethods
  end

  module InstanceMethods
    def reenumerate_children(updatecf = false)
      # chs = self.children.where.not(cosmosys_issue_id: nil)
      chs = []
      self.issues.where(parent_id: nil).each{|c|
        csys = CosmosysIssue.find_by_issue_id(c)
        if (csys != nil) then
          chs += [csys]
        end
      }
=begin
      puts("antes de reordenar")
      chs.each{|ch|
        puts(ch.csys.get_identifier+' '+ch.chapter_order.to_s)
      }
=end
      chs2 = chs.sort_by{|obj| obj.chapter_order}
=begin
      puts("despues de reordenar")
      chs2.each{|ch|
        puts(ch.csys.get_identifier+' '+ch.chapter_order.to_s)
      }
=end
      i = 1
      chs2.each{|ch|
        #puts('Antes: '+i.to_s+' '+ch.csys.get_identifier+' '+ch.chapter_order.to_s)
        if (ch.chapter_order.floor != i) then
          ch.chapter_order = i
          ch.save
          #puts('Despues: '+i.to_s+' '+ch.csys.get_identifier+' '+ch.chapter_order.to_s)
          if (updatecf) then
            # puts("-----------")
            ch.update_cschapter
          end
        end
        # puts("+++++++++")
        i += 1
      }
      return i
    end

    def csys
      if self.cosmosys_project == nil then
        CosmosysProject.create!(project: self)
      end
      self.cosmosys_project
    end

    def code
      self.csys.code
    end

    def id_counter
      self.csys.id_counter
    end

    def validate_csreportmetadata

      cf = ProjectCustomField.find_by_name("csReportMetadata")
      puts self.custom_field_values
      if cf != nil then
        cv = self.custom_field_values.select{|a| a.custom_field_id == cf.id }.first
        if cv != nil then
          begin
            metadata_yaml = YAML.load(cv.value)
          rescue Exception
            errors.add(:csReportMetadata,"Invalid YAML description")
          end
        end
      end
    end

  end
end
# Add module to Project
Project.send(:include, ProjectPatch)
