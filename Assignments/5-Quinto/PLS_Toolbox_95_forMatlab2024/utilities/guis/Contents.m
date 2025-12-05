% PLS_TOOLBOX Graphical User Interface Utilties.
%
%   adjustaxislimitsgui         - for given figure allows adjustment of current axis limits.
%   analysistypes               - Return information on enabled GUI analysis methods.
%   autodocsettings             - Simple interface for setting auto docking features of PLS_Tool box.
%   autoset                     - GUI used to modfiy settings of AUTO.
%   baselineset                 - GUI to choose baseline settings for Preprocess
%   browse_shortcuts            - defines shortcuts available on the EVRI Workspace Browser
%   browseicons                 - retrieve icons for the EVRI Workspace Browser
%   caltransfergui              - M-file for caltransfergui.fig
%   choosencomp                 - GUI to select number of components from SSQ table.
%   cls_guifcn                  - Analysis-specific methods for Analysis GUI.
%   cluster_guifcn              - CLUSTER Analysis-specific methods for Analysis GUI.
%   crossvalgui                 - Cross-Validation.
%   decompose                   - Principal Components Analysis with graphical user interface.
%   delobj_timer                - Automatically delete a given object after a period of time
%   detrendset                  - GUI used to modfiy settings of DETREND.
%   displaydatagui              - M-file for displaydatagui.fig
%   editds_defaultimportmethods - Returns list of import methods for GUIs.
%   editds_importmethods        - List of user-defined import methods for DataSet Editor
%   editds_mtfimport            - DSO Import function for EditDS
%   editds_userimport           - MYREADR Example user-defined importer for editds
%   editdsicons                 - Utility for EDITDS containing icon images.
%   editlookup                  - Edit a class lookup table.
%   erdlgpls                    - Error dialog.
%   evricommentdlg              - Expanded dialog box for large comments.
%   evrierrordlg                - Overload standard error dialog for automation management.
%   evrihelp                    - Provide help on a given topic for a given mfile.
%   evrihelpdlg                 - Overload standard warning dialog for automation management.
%   evrimsgbox                  - Overload standard message dialog for automation management.
%   evriquestdlg                - Overload standard question dialog for automation management.
%   evritable                   - Create java table that works from ML 7.0.4+
%   evritip                     - Show a tip for a specified feature.
%   evritree                    - Creates a tree view of cached datasets, models, and predections.
%   evriuigetdir                - Overload putfile function for directory management.
%   evriuigetfile               - Overload getfile function for directory management.
%   evriuiputfile               - Overload putfile function for directory management.
%   evriupdatesettings          - M-file for evriupdatesettings.fig
%   evriwarndlg                 - Overload standard warning dialog for automation management.
%   flowchart_callback          - Manage the Analysis GUI flowchart frame.
%   flowchart_list              - Generate context-senstive list of flowchart objects
%   gcluster                    - GUI function for use with CLUSTER.
%   glswset                     - M-file for glswset.fig
%   gscaleset                   - GUI used to modfiy settings for gscale.
%   infobox                     - Display a text message in an information box.
%   initfigure                  - Initialization code for solo figures.
%   iplsgui                     - Panel gui for ipls in analysis.
%   knn_guifcn                  - CLUSTER_GUIFCN CLUSTER Analysis-specific methods for Analysis GUI.
%   lamsel                      - Determines indices of wavelength axes in specified ranges.
%   lddlgpls                    - Dialog to load variable from workspace or MAT file.
%   logdecayset                 - GUI used to modfiy settings of LOGDECAY.
%   lwr_guifcn                  - Analysis-specific methods for Analysis GUI.
%   lwrgui                      - M-file for lwrgui.fig
%   mcr_guifcn                  - Analysis-specific methods for Analysis GUI.
%   medcnset                    - Returns default median centering preprocessing structure.
%   mncnset                     - Returns default mean centering preprocessing structure.
%   modelviewcb                 - Internal utility function for modelviewer.
%   modelviewertool             - Unsupported utility.
%   moveto                      - moves pointer to a given GUI object
%   mpca_guifcn                 - Analysis-specific methods for Analysis GUI.
%   mscorrset                   - GUI used to modfiy settings of MSCORR (MSC).
%   nextmode                    - Uspported utility.
%   normset                     - GUI used to modfiy settings of NORMALIZ.
%   npreprocenterset            - GUI used to modfiy settings of NPREPROCESS for centering.
%   npreproscaleset             - GUI used to modfiy settings of NPREPROCESS for scaling.
%   optionsgui                  - creates options gui for specified function.
%   orderclasses                - Arranges classes into color and symbol-friendly order.
%   oscset                      - GUI used to modfiy settings of Orthogonal Signal Correction GUI.
%   panelmanager                - Manages basic tasks of adding contents of fig file to an existing ui frame.
%   parafac_guifcn              - PARAFAC Analysis-specific methods for Analysis GUI.
%   pca_guifcn                  - PCA analysis-specific methods for Analysis GUI.
%   piconnectgui                - M-file for piconnectgui.fig
%   plotgui_plotscatter         - scatter plot of dataset object
%   plotgui_toolbar             - Add toolbar to plotgui target figure
%   plotguitypes                - Helper function for plotgui scatter plots.
%   plsda_guifcn                - Analysis-specific methods for Analysis GUI.
%   plsdagui                    - M-file for plsdagui.fig
%   positionmanager             - Manages stored figure position using keyword.
%   prefexpert                  - M-file for prefexpert.fig
%   prefobjcb                   - Callback utility for optionsgui.
%   prefobjplace                - sets up the options gui for a specific function.
%   preproloop                  - GUI used to modfiy settings for preprocess looping.
%   purity_guifcn               - Analysis-specific methods for Analysis GUI
%   reg_guifcn                  - Regression Analysis-specific methods for Analysis GUI.
%   regression                  - Regression with graphical user interface.
%   savemodelas                 - Opens dialog box for saving a model.
%   savemodelas_customlist      - List of user-defined "save as" methods for saving models.
%   savemodelas_examplefunc     - Simple example of custom "save as" function.
%   savgolset                   - GUI used to modfiy settings of SAVGOL.
%   scriptexpert                - M-file for scriptexpert.fig
%   simca_guifcn                - SIMCA Analysis-specific methods for Analysis GUI.
%   simcagui                    - M-file for simcagui.fig.
%   snvset                      - GUI used to modfiy settings of SNV.
%   svdlgpls                    - Dialog to save variable to workspace or MAT file.
%   svm_guifcn                  - SVM Analysis-specific methods for Analysis GUI.
%   symbolstyle                 - M-file for symbolstyle.fig
%   toolbar                     - Creates toolbar and assigns correct callback functions. 
%   toolbar_buttonsets          - Defines standard button sets for analysis methods.
%   trendapply                  - Apply trend tool markers to data.
%   trendlink                   - Uses marker objects to extract trend information.
%   trendmarker                 - Manages marker objects for trendtool.
%   trendwaterfall              - waterfall for trendtool
%   wlsbaselineset              - GUI used to modfiy settings of of WLSBASELINE.
%   textreadrgui                 - M-file for textreadrgui.fig
