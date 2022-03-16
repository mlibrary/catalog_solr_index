$:.unshift "#{File.dirname(__FILE__)}/../lib"

require_relative '../lib/umich_traject'
extend Traject::Macros::UMich::SubjectMacros

################################
######## SUBJECT / TOPIC  ######
################################

# We get the full topic (LCSH), but currently want to ignore
# entries that are FAST entries (those having second-indicator == 7)

remediated_subjects = Traject::TranslationMap.new('umich/remediated_subjects')

skip_FAST = ->(rec, field) do
  field.indicator2 == '7' and field['2'] =~ /fast/
end

to_field "topic", extract_marc_unless(%w(
  600a  600abcdefghjklmnopqrstuvxyz
  610a  610abcdefghklmnoprstuvxyz
  611a  611acdefghjklnpqstuvxyz
  630a  630adefghklmnoprstvxyz
  648a  648avxyz
  650a  650abcdevxyz
  651a  651aevxyz
  653a  653abevyz
  654a  654abevyz
  655a  655abvxyz
  656a  656akvxyz
  657a  657avxyz
  658a  658ab
  662a  662abcdefgh
  690a   690abcdevxyz

  ), skip_FAST, :trim_punctuation => true) do |rec, acc|

    acc.map! do |subj|
      #if !remediated_subjects[subj].nil?
        #nil
      #else
        #subj
      #end

      if remediated_subjects.to_hash.keys.find { |key| subj.match?(/^#{key}/) }.nil?
        subj
      else 
        nil
      end
    end
    acc.compact!
  end

to_field 'lc_subject_display', lcsh_subjects do |rec, acc, context|
  remediated_lc_list = Array.new
  acc.map! do |subj|
    subjects = subj.split(' -- ')
    if !remediated_subjects[subjects.first].nil?
      subjects[0] = remediated_subjects[subjects.first]

      remediated_lc_list.push(subjects.join(' -- ') )
      nil
    else
      subj
    end
  end
  context.clipboard[:remediated_lc_subjects] = remediated_lc_list
  acc.compact!
  #put them in context clipboard
end

to_field 'non_lc_subject_display', non_lcsh_subjects do |rec, acc, context|
  context.clipboard[:remediated_lc_subjects].each {|subj| acc << subj }
end

to_field 'topic', extract_marc("600a:610a:611a:630a:648a:650a:651a:653a:654a:655a:656a:657a:658a:662a:690a", :translation_map => 'umich/remediated_subjects')

to_field 'topic' do |rec, acc, context|
  context.clipboard[:remediated_lc_subjects].each{|x| acc << x.split(" -- ").join(" ") }
end

