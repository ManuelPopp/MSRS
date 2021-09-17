"""
Created on Wed Sep 15 19:56:34 2021
Random sampling of rectangular cells (extracted from a fishnet grid) from large raster files
Name : Sample_Grid_Cells
Group : MSRS
With QGIS : 31416
@author: Manuel
Using QGIS 3.14.16
"""

from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterRasterLayer
from qgis.core import QgsProcessingParameterVectorLayer
from qgis.core import QgsProcessingParameterRasterDestination
from qgis.core import QgsProcessingParameterNumber
from qgis.core import QgsProcessingParameterFolderDestination
from qgis.core import QgsVectorLayer
from qgis.core import Qgis
import processing
import random, os
from qgis.core import QgsMessageLog
class Model(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterRasterLayer("RGBraster", "RGB_raster", defaultValue=None))
        self.addParameter(QgsProcessingParameterRasterLayer("IRraster", "IR_raster", defaultValue=None))
        self.addParameter(QgsProcessingParameterRasterLayer("Landcoverraster", "Landcover_raster", defaultValue=None))
        self.addParameter(QgsProcessingParameterVectorLayer("FishnetGrid", "Fishnet_Grid", types=[QgsProcessing.TypeVectorPolygon], defaultValue=None))
        #self.addParameter(QgsProcessingParameterRasterDestination("Rgb", "RGB", createByDefault=True, defaultValue=None))
        #self.addParameter(QgsProcessingParameterRasterDestination("Ir", "IR", createByDefault=True, defaultValue=None))
        #self.addParameter(QgsProcessingParameterRasterDestination("Landcover", "Landcover", createByDefault=True, defaultValue=None))
        self.addParameter(QgsProcessingParameterNumber("N", "N", type=QgsProcessingParameterNumber.Integer, defaultValue=None))
        self.addParameter(QgsProcessingParameterFolderDestination("Directory", "Directory", defaultValue=""))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(3, model_feedback)
        results = {}
        outputs = {}
        
        # loop over sample subset
        n = parameters["N"]
        grid = self.parameterAsSource(parameters, "FishnetGrid", context)
        cells = grid.featureCount()
        QgsMessageLog.logMessage(("Number of grid cells = " + str(cells)), level = Qgis.Info)
        sample = random.sample(range(1, cells), n)
        for i in sample:
            
            # Create output directories
            drctry = parameters["Directory"]
            X_RGB_dir = os.path.join(drctry, "X_RGB")
            X_IR_dir = os.path.join(drctry, "X_IR")
            y_dir = os.path.join(drctry, "y")
            os.makedirs(X_RGB_dir, exist_ok = True)
            os.makedirs(X_IR_dir, exist_ok = True)
            os.makedirs(y_dir, exist_ok = True)
            
            # Select grid cell
            # Extract by attribute
            alg_params = {
                "FIELD": "id",
                "INPUT": parameters["FishnetGrid"],
                "OPERATOR": 0,
                "VALUE": i,
                "OUTPUT": QgsProcessing.TEMPORARY_OUTPUT
            }
            outputs["ExtractByAttribute"] = processing.run("native:extractbyattribute", alg_params, context=context, feedback=feedback, is_child_algorithm=True)
    
            feedback.setCurrentStep(1)
            if feedback.isCanceled():
                return {}
    
            # Clip raster by extent
            alg_params = {
                "DATA_TYPE": 0,
                "EXTRA": "",
                "INPUT": parameters["RGBraster"],
                "NODATA": None,
                "OPTIONS": "",
                "PROJWIN": outputs["ExtractByAttribute"]["OUTPUT"],
                "OUTPUT": os.path.join(X_RGB_dir, str(i) + ".tif")
            }
            outputs["ClipRasterByExtent"] = processing.run("gdal:cliprasterbyextent", alg_params, context=context, feedback=feedback, is_child_algorithm=True)
            results["Rgb"] = outputs["ClipRasterByExtent"]["OUTPUT"]
    
            feedback.setCurrentStep(1)
            if feedback.isCanceled():
                return {}
            
            # Clip raster by extent
            alg_params = {
                "DATA_TYPE": 0,
                "EXTRA": "",
                "INPUT": parameters["IRraster"],
                "NODATA": None,
                "OPTIONS": "",
                "PROJWIN": outputs["ExtractByAttribute"]["OUTPUT"],
                "OUTPUT": os.path.join(X_IR_dir, str(i) + ".tif")
            }
            outputs["ClipRasterByExtent"] = processing.run("gdal:cliprasterbyextent", alg_params, context=context, feedback=feedback, is_child_algorithm=True)
            results["Ir"] = outputs["ClipRasterByExtent"]["OUTPUT"]
    
            feedback.setCurrentStep(2)
            if feedback.isCanceled():
                return {}
    
            # Clip raster by extent
            alg_params = {
                "DATA_TYPE": 0,
                "EXTRA": "",
                "INPUT": parameters["Landcoverraster"],
                "NODATA": None,
                "OPTIONS": "",
                "PROJWIN": outputs["ExtractByAttribute"]["OUTPUT"],
                "OUTPUT": os.path.join(y_dir, str(i) + ".tif")
            }
            outputs["ClipRasterByExtent"] = processing.run("gdal:cliprasterbyextent", alg_params, context=context, feedback=feedback, is_child_algorithm=True)
            results["Landcover"] = outputs["ClipRasterByExtent"]["OUTPUT"]
            
            print(i)
        return None

    def name(self):
        return "model"

    def displayName(self):
        return "model"

    def group(self):
        return ""

    def groupId(self):
        return ""

    def createInstance(self):
        return Model()
