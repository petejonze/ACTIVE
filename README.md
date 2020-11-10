# ACTIVE
Automated preferentrial looking acuity test for infants

### System Requirements
**Hardware:**
- The system was developed with a Tobii x120, and should support most Tobii models. Technically any eyetracker can be connected via the "ivis" interface (the test itself just pulls data from ivis, and so is device agnostic)
- A high resolution monitor is also required
- For accurate data, the monitor needs to be calibrated with a photometer

**Programming language:**
- Matlab 2012 or newer, running on Windows, Mac, or Linux (32 or 64 bit). Note that older versions of Matlab will not work, due to the heavy reliance on relatively modern, Object-Oriented features - sorry.
- In Windows GStreamer may also be required in order to play videos (see Psychtoolbox help for info)

**Dependencies (MATLAB toolkits):**
- Psychtoolbox [free, 3rd party toolkit]
- Matlab binding for your eyetracker (e.g., the Tobii Matlab SDK v3.0)
- ivis (available here: https://github.com/petejonze/ivis )
- PsychTestRig (included)
- Possibly some internal MATLAB toolboxes (not sure?)

**License:**
GNU GPL v3.0

### To cite and for more info
[Jones, P. R., Kalwarowsky, S., Atkinson, J., Braddick, O. J. & Nardini, M. (2014). Automated measurement of resolution acuity in infants using remote eye-tracking, Investigative Ophthalmology and Vision Science, 55(12):8102-8110, doi:[10.1167/iovs.14-15108]](https://iovs.arvojournals.org/article.aspx?articleid=2212669)

[Jones, P. R., Kalwarowsky, S., Braddick, O. J., Atkinson, J. & Nardini, M. (2015). Optimizing the rapid measurement of detection thresholds in infants, Journal of Vision, 15(11):2, doi:[10.1167/15.11.2]](https://jov.arvojournals.org/article.aspx?articleid=2423009)


### Video of OpenVisSim in action
[Video of ACTIVE in action](https://www.dropbox.com/s/3gtd35s93s5xraj/screencapture_acuity.wmv?dl=0)

### Acknowledgments
Development of the simulator was supported by Fight for Sight (UK) and by the NIHR Biomedical Research Centre located at (both) Moorfields Eye Hospital and UCL Institute of Ophthalmology.

### Contact me
For any questions/comments, feel free to email me at: peter.jones@city.ac.uk

### Enjoy!
@petejonze  
10/11/2020