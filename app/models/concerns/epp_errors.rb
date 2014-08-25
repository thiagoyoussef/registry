module EppErrors
  extend ActiveSupport::Concern

  def construct_epp_errors
    epp_errors = []
    errors.messages.each do |key, values|
      if self.class.reflect_on_association(key)
        epp_errors << collect_child_errors(key)
      end

      epp_errors << collect_parent_errors(key, values)
    end

    errors[:epp_errors] = epp_errors
    errors[:epp_errors].flatten!
  end

  def collect_parent_errors(key, values)
    epp_errors = []
    values = [values] if values.is_a?(String)

    values.each do |err|
      if err.is_a?(Hash)
        next unless code = find_epp_code(err[:msg])
        err_msg = { code: code, msg: err[:msg] }
        err_msg[:value] = { val: err[:val], obj: err[:obj] } if err[:val]
        epp_errors << err_msg
      else
        next unless code = find_epp_code(err)
        err = { code: code, msg: err }

        # If we have setting relation, then still add the value to the error message
        # If this sort of exception happens again, some other logic has to be implemented
        if self.class.reflect_on_association(key) && key == :setting
          err[:value] = { val: send(key).value, obj: self.class::EPP_ATTR_MAP[key] }

        # if the key represents other relations, skip value
        elsif !self.class.reflect_on_association(key)
          err[:value] = { val: send(key), obj: self.class::EPP_ATTR_MAP[key] }
        end

        epp_errors << err
      end
    end
    epp_errors
  end

  def collect_child_errors(key)
    macro = self.class.reflect_on_association(key).macro
    multi = [:has_and_belongs_to_many, :has_many]
    single = [:belongs_to, :has_one]

    epp_errors = []
    send(key).each do |x|
      x.errors.messages.each do |key, values|
        epp_errors << x.collect_parent_errors(key, values)
      end
    end if multi.include?(macro)

    epp_errors
  end

  def find_epp_code(msg)
    epp_code_map.each do |code, values|
      values.each do |x|
        t = errors.generate_message(*x) if x.is_a?(Array)
        t = x if x.is_a?(String)
        return code if t == msg
      end
    end
    nil
  end
end
