
class InstallPane extends Pane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @submit.bind(@)
      buttons               :
        install             :
          title             : "Install Drupal"
          style             : "cupid-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
        advanced            :
          itemClass         : KDToggleButton
          style             : "transparent"
          states          : [
            "Advanced Options", (callback)=>
              @form.buttons.advanced.setClass "toggle"
              darks = @form.$ '.formline.dark'
              darks.addClass "in"
              callback? null
            "&times; Advanced Options", (callback)=>
              @form.buttons.advanced.unsetClass "toggle"
              darks = @form.$ '.formline.dark'
              darks.removeClass "in"
              callback? null
          ]
      fields                :
        name                :
          label             : "Name of your Drupal site:"
          name              : "name"
          placeholder       : "type a name for your Drupal site..."
          defaultValue      : "My Drupal"
          validate          :
            rules           :
              required      : "yes"
            messages        :
              required      : "a name for your Drupal site is required!"
          keyup             : => @completeInputs()
          blur              : => @completeInputs()
        domain              :
          label             : "Domain :"
          name              : "domain"
          itemClass         : KDSelectBox
          defaultValue      : "#{nickname}.koding.com"
          nextElement       :
            pathExtension   :
              label         : "/my-drupal/"
              type          : "hidden"
        path                :
          label             : "Path :"
          name              : "path"
          placeholder       : "type a path for your Drupal site..."
          hint              : "leave empty if you want your Drupal site to work on your domain root"
          defaultValue      : "my-drupal"
          keyup             : => @completeInputs yes
          blur              : => @completeInputs yes
          validate          :
            rules           :
              regExp        : /(^$)|(^[a-z\d]+([-][a-z\d]+)*$)/i
            messages        :
              regExp        : "please enter a valid path!"
          nextElement       :
            timestamp       :
              name          : "timestamp"
              type          : "hidden"
              defaultValue  : Date.now()
        Database            :
          label             : "Create a new database:"
          name              : "db"
          cssClass          : "dark"
          title             : ""
          labels            : ["YES","NO"]
          itemClass         : KDOnOffSwitch
          defaultValue      : yes

    @form.on "FormValidationFailed", => @form.buttons["Install Drupal"].hideLoader()

    domainsPath = "/Users/#{nickname}/Sites"

    kc.run "ls #{domainsPath} -lpva"
    , (err, response)=>
      if err then warn err
      else
        files = FSHelper.parseLsOutput [domainsPath], response
        newSelectOptions = []

        files.forEach (domain)->
          newSelectOptions.push {title : domain.name, value : domain.name}

        {domain} = @form.inputs
        domain.setSelectOptions newSelectOptions

  completeInputs:(fromPath = no)->

    {path, name, pathExtension} = @form.inputs
    if fromPath
      val  = path.getValue()
      slug = KD.utils.slugify val
      path.setValue val.replace('/', '') if /\//.test val
    else
      slug = KD.utils.slugify name.getValue()
      path.setValue slug

    slug += "/" if slug

    pathExtension.inputLabel.updateTitle "/#{slug}"

  submit:(formData)=>

    split.resizePanel 250, 0
    {path, domain, name, db} = formData
    formData.timestamp = parseInt formData.timestamp, 10
    formData.fullPath = "#{domain}/website/#{path}"

    failCb = =>
      @form.buttons["Install Drupal"].hideLoader()
      @utils.wait 5000, -> split.resizePanel 0, 1

    successCb = (dbinfo)=>
      installWordpress formData, dbinfo, (path, timestamp)=>
        @emit "DrupalInstalled", formData
        @form.buttons["Install Drupal"].hideLoader()
    
    checkPath formData, (err, response)=>
      console.log arguments
      if err # means there is no such folder
        if db
          prepareDb (err, dbinfo)=> if err then failCb() else successCb dbinfo
        else
          successCb()
      else # there is a folder on the same path so fail.
        failCb()

  pistachio:-> "{{> @form}}"
