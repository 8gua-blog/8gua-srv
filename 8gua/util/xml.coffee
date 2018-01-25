module.exports = {
    cdata : (str)->
      if not str
        return ''
      return '<![CDATA['+str.split("]]>").join(']]]]><![CDATA[>')+']]>'
}

