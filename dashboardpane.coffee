class DashboardPane extends Pane

  constructor:->

    super

    @listController = new KDListViewController
      lastToFirst     : yes
      viewOptions     :
        type          : "wp-blog"
        itemClass     : InstalledAppListItem

    @listWrapper = @listController.getView()

    @notice = new KDCustomHTMLView
      tagName : "p"
      cssClass: "why-u-no"
      partial : "y u no create Drupal!!!"

    @notice.hide()

    @loader = new KDLoaderView
      size          :
        width       : 60
      cssClass      : "loader"
      loaderOptions :
        color       : "#ccc"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24
    
    @listController.getListView().on "DeleteLinkClicked", (listItemView)=>

      {path, domain, name} = listItemView.getData()
      
      userDir = "/Users/#{nickname}/Sites/#{domain}/website/"
      
      if path.trim() is ""
        path    = ""
        message = "Oh, its installed to root! This action will just remove this Drupal from list, <strong>you need to delete files manually</strong>."
        command = ""
        warning = ""
      else
        message = "<pre>#{userDir}#{path}</pre>"
        command = "rm -r '#{userDir}#{path}'"
        warning = """<p class='modalformline' style='color:red'>
                        Warning: This will remove everything under that directory!
                     </p>"""
      
      modal = new KDModalView
        title          : "Are you sure want to delete this Drupal?"
        content        : """
                          <div class='modalformline'>
                            <p>#{message}</p>
                          </div>
                          #{warning}
                         """
        height         : "auto"
        overlay        : yes
        width          : 500
        buttons        :
          Delete       :
            style      : "modal-clean-red"
            loader     :
              color    : "#ffffff"
              diameter : 16
            callback   : =>
              @removeItem listItemView
              if path is ""
                modal.buttons.Delete.hideLoader()
                modal.destroy()
              else
                split.resizePanel 250, 0
                parseOutput "<br><br>Deleting /Users/#{nickname}/Sites/#{domain}/website/#{path}<br><br>"
                parseOutput command
                kc.run withArgs : {command} , (err, res)=>
                  modal.buttons.Delete.hideLoader()
                  modal.destroy()
                  if err
                    parseOutput err, yes
                    new KDNotificationView
                      title    : "There was an error, you may need to remove it manually!"
                      duration : 3333
                  else
                    parseOutput "<br><br>#############"
                    parseOutput "<br>#{name} successfully deleted."
                    parseOutput "<br>#############<br><br>"
                    tc.refreshFolder tc.nodes["/Users/#{nickname}/Sites/#{domain}/website"]
                    
                  @utils.wait 1500, ->
                    split.resizePanel 0, 1
  
  removeItem:(listItemView)->

    blogs = appStorage.getValue "blogs"
    blogToDelete = listItemView.getData()
    blogs.splice blogs.indexOf(blogToDelete), 1
    
    appStorage.setValue "blogs", blogs, =>
      @listController.removeItem listItemView
      appStorage.fetchValue "blogs", (blogs)=>
        blogs?=[]
        @notice.show() if blogs.length is 0

  putNewItem:(formData, resizeSplit = yes)->

    tabs = @getDelegate()
    tabs.showPane @
    @listController.addItem formData
    @notice.hide()
    if resizeSplit
      @utils.wait 1500, -> split.resizePanel 0, 1

  viewAppended:->

    super

    @loader.show()

    appStorage.fetchStorage (storage)=>
      @loader.hide()
      blogs = appStorage.getValue("blogs") or []
      if blogs.length > 0
        blogs.sort (a, b) -> if a.timestamp < b.timestamp then -1 else 1
        blogs.forEach (item)=> @putNewItem item, no
      else
        @notice.show()

  pistachio:->
    """
    {{> @loader}}
    {{> @notice}}
    {{> @listWrapper}}
    """

class InstalledAppListItem extends KDListItemView

  constructor:(options, data)->

    options.type = "wp-blog"

    super options, data

    @delete = new KDCustomHTMLView
      tagName : "a"
      cssClass: "delete-link"
      click   : => @getDelegate().emit "DeleteLinkClicked", @

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()
    @utils.wait => @setClass "in"

  pistachio:->
    {path, timestamp, domain, name} = @getData()
    url = "http://#{domain}/#{path}"
    """
    {{> @delete}}
    <a target='_blank' class='name-link' href='#{url}'>{{ #(name)}}</a>
    <a target='_blank' class='admin-link' href='#{url}#{if path is "" then '' else '/'}wp-admin'>Admin</a>
    <a target='_blank' class='raw-link' href='#{url}'>#{url}</a>
    <time datetime='#{new Date(timestamp)}'>#{$.timeago new Date(timestamp)}</time>
    """

