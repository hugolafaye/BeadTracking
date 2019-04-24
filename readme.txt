==========================================================================
 BeadTracking MATLAB package (https://github.com/hugolafaye/BeadTracking)
==========================================================================


___________
Description

This MATLAB code implements two tracking algorithms: one based on a simple
deterministic approach in two steps (object detection and detected object
tracking) and another based on a multi-model particle filter approach with
switching dynamical state. It also provides an evaluation of the tracking
results on ground truth datasets.

It is free for research use. If you find it useful, please acknowledge the
first paper [1] of the references section.

Version 2.0 - tested on MATLAB R2014a and R2018b

By  Hugo Lafaye de Micheaux (1,2) - hugo.lafaye-de-micheaux@irstea.fr
and Thomas Gautrais (1)           - thomas.gautrais@univ-st-etienne.fr

Collaborators:
Christophe Ducottet (1) - ducottet@univ-st-etienne.fr
Philippe Frey (2)       - philippe.frey@irstea.fr

(1) Laboratoire Hubert Curien UMR 5516, Université de Lyon, UJM-Saint-Etienne,
    CNRS, IOGS, F-42023, Saint-Etienne, France
(2) Univ. Grenoble Alpes, Irstea, ETNA, 38000 Grenoble, France


____________
Requirements

The code is prepared to run on sequences of images having trackable black
and/or transparent spherical beads. It requires the MATLAB Image Processing
Toolbox, the MATLAB Statistics Toolbox for the particle filter-based tracking
and can require the MATLAB Parallel Computing Toolbox if asked (optionnal but
highly recommended for long datasets).


__________
Quickstart

1. Extract the code somewhere.

2. Launch MATLAB, choose current folder to be the package folder and execute
   the script 'InstallPackage.m' to add all the functions of the package in the
   MATLAB workspace.

3. If you don't have sequences of images already, in addition to the short
   dataset given in the 'Data' folder of the package, some datasets can be
   downloaded executing 'DownloadDatasets.m' (may take some time) or directly
   at https://dossier.univ-st-etienne.fr/ltsi/public/Dataset/BeadTrackingData/

4. Execute 'ImageViewer.m' to visualize a sequence of images, or execute
   'PlayVideoImageSequence.m' to create a video of a sequence of images.

5. Execute 'RunDetection.m' without parameters to launch a user interface that
   will guide the setting of all detection parameters, then click 'run' button
   to compute the objects detection.

6. Once the objects have been detected, execute 'RunTracking.m' the same way
   for the setting of all tracking parameters, then click 'run' button to 
   compute the deterministic tracking of the detected objects.

7. Execute 'RunTrackingPF.m' the same way to compute the multi-model particle
   filter tracking. No user interface here, default parameter values will be
   used in this simple call.

8. Execute 'RunEvaluation.m' without parameters to launch an evaluation of
   the tracking algorithms. Several dialog boxes will pop up to set some
   parameters. The evaluation results will then be shown on several plots.


__________
How to use

The main interfaces 'RunDetection.m', 'RunTracking.m' and 'RunTrackingPF.m'
can be called with several configurations specified in the function
descriptions.

Here are some details about the detection parameters:

- File of sequence parameters: to run on a sequence of images, a file of
  parameters, specific to the sequence, is needed and will never change. It is
  as follows and is called 'sequence_param.txt' (name can be different):
  
  diamBlackBead	0.006	m
  diamTransBead	0.004	m
  rateDiamTransBeadInside	0.6	oftotaldiam
  mByPx	0.0002056	m/px
  acqFreq	130	im/s
  vMax	0.83	m/s
  flumeDirection	-1	righttoleft
  
  diamBlackBead and diamTransBead are the diameters of the black and transparent
  beads (in meter), rateDiamTransBeadInside is the percentage of the inside
  diameter of the transparent beads over the outside diameter of the transparent
  beads (indeed transparent beads look like rings in the images), mByPx is the
  real size of a pixel of the image (in meter),acqFreq is the acquisition
  frequency, vMax is the maximum velocity the objects can reach during all the
  sequence, flumeDirection defines the flux direction.
  
  To create a sequence parameters file, copy-paste the above example or directly
  the file in the example data of the package, and modify the parameters to 
  correspond to the sequence. In the file, the spaces must to be tabulations.
  
- File of base mask: according to the camera position, the fixed base of the
  flume can appear in images and badly impact the object detection. In this
  case, its influence can be removed from the images during the detection  
  thanks to a pre-computed mask containing its positions. The mask is stored in
  a file called 'sequence_base_mask.tif' (name can be different).
  
- File of transparent bead template: to run the detection of transparent beads,
  a template is needed. It has to be created once and for all by running
  'RunCreateTemplateTransparentBead.m'. All information needed to create the
  template file is given in the function file. The template is stored in a file
  called 'template_transparent_bead_rOut??_rIn??.mat' (name can be different).
  
- 'threshBlackBeadDetect' parameter: it corresponds to the threshold separating
  black pixels from the rest ([0,255]). Often between 15 and 50, it can be set
  automatically if set to a negative value (eg. -1) in the GUI. It can also be
  set manually by looking at pixel intensities in an image (eg. by executing
  PlotImage(imread(uigetfile('*.tif')),0);impixelinfo;)
  
- 'threshTransBeadDetect' parameter: it corresponds to the threshold to detect
  transparent beads ([0,1]). It is used to determine if a correlation with the
  template is high enough to be considered as a transparent bead.

- 'threshTransBeadDetectConf' parameter: it corresponds to the threshold of the
  detector confidence to detect transparent beads ([0,1]). It should be smaller
  than 'threshTransBeadDetect'. It is only used for a further execution of a
  multi-model particle filter-based tracking.
  
- The four other value parameters should not be changed if user is not informed
  on their specific use. The detection runs very well with default values.
  
- Please read paper [1] and PhD thesis [2] for more details about these
  detection parameters and their setting.


Here are some details about the deterministic tracking parameters:

- File of detection results: to run the object tracking, detection results are
  needed. So run detection before tracking.

- The three value parameters for the computation of motion states should not be
  changed if user is not informed on their specific use.
  
- Please read paper [4] or PhD thesis [2] for more details about these tracking
  parameters and their setting.


Here are some details about the multi-model particle filter-based tracking
parameters:

- Because of the high number of parameters, no user interface is used. Instead,
  launch the algorithm a first time, that will set all parameters to default
  values. Then you can change their values in the file of parameters or in the
  structure variable and launch it again.

- Please read paper [1] for more details about these tracking parameters and 
  their setting.


___________
Data format

The detection results are stored in a '.mat' file which contains especially the
variable 'detectData' being a cell array of detection matrices. There is one
detection matrix for each image of the sequence. A detection matrix has 3 infos
(col) for each detection (row) of the image:
  1. x-coordinate of the detection
  2. y-coordinate of the detection
  3. category of the detection ('0' for black bead, '1' for transparent bead)

The tracking results are stored in a '.mat' file which contains especially the
variable 'trackData' being a cell array of tracking matrices. There is one
tracking matrix for each image of the sequence. A tracking matrix has 9 infos
(col) for each target (row) of the image:
  1. x-coordinate of the target
  2. y-coordinate of the target
  3. category of the target ('0' for black bead, '1' for transparent bead)
  4. target identity ('NaN' if removed)
  5. x-velocity of the target
  6. y-velocity of the target
  7. row of the target in previous tracking matrix ('0' if no previous)
  8. row of the target in next tracking matrix ('0' if no next)
  9. motion state of the target ('0' for resting, '1' for rolling, '2' for
     saltating, '3' for unknown)
It also contains the variable 'trackInfo' being a matrix of target information.
A target (row) has 3 infos (col):
  1. image number where the target starts
  2. length of the target
  3. nb of effective detections of the target along its trajectory (only for
     particle filter-based tracking)


_______________
Version history

2.0 - Apr 24, 2019
  * Add the multi-model particle filter-based tracking algorithm
  * Add the evaluation of the tracking algorithms against ground truths
  * Add the detection confidence output to the detection step
  * Add the possibility to download some datasets with their ground truth
  * Made minor corrections to function descriptions

1.0 - Mar 28, 2019
  * Initial release


__________
References

[1] Lafaye de Micheaux, H., Ducottet, C., Frey, P. (2018). Multi-model particle
    filter-based tracking with switching dynamical state to study bedload
    transport. Machine Vision and Applications, Springer Nature, 29(5), 735-747.
    doi: https://doi.org/10.1007/s00138-018-0925-z

[2] Lafaye de Micheaux, H. (2017). Image processing for segregation in bedload
    sediment transport: morphology and tracking. PhD Thesis in French,
	Université de Lyon.
	url: https://tel.archives-ouvertes.fr/tel-02102694
	
[3] Lafaye de Micheaux, H., Ducottet, C., Frey, P. (2016). Online multi-model
    particle filter-based tracking to study bedload transport. International
	Conference on Image Processing (ICIP), IEEE, 3489-3493.
	doi: https://doi.org/10.1109/ICIP.2016.7533008

[4] Hergault, V., Frey, P., Métivier, F., Barat, C., Ducottet, C., Böhm, T.,
    Ancey, C. (2010). Image processing for the study of bedload transport of
	two-size spherical particles in a supercritical flow. Experiments in Fluids,
	Springer, 49(5), 1095-1107.
	doi: https://doi.org/10.1007/s00348-010-0856-6
	
[5] Böhm, T., Frey, P., Ducottet, C., Ancey, C., Jodeau, M., Reboud, J.-L
    (2006). Two-dimensional motion of a set of particles in a free surface flow
	with image processing. Experiments in Fluids, Springer, 41(1), 1-11.
	doi: https://doi.org/10.1007/s00348-006-0134-9