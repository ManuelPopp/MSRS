"""
Recalculate raster values to aggregate classes
Name : SimplifyRasters
Group : MSRS
With QGIS : 31416
@author: Manuel
Using QGIS 3.14.16
"""

from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterRasterLayer
from qgis.core import QgsProcessingParameterRasterDestination
import processing


class Model(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterRasterLayer('InputRaster', 'Input_Raster', defaultValue=None))
        self.addParameter(QgsProcessingParameterRasterDestination('Output', 'Output', createByDefault=True, defaultValue=None))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(1, model_feedback)
        results = {}
        outputs = {}

        # Raster calculator
        alg_params = {
            'CELLSIZE': 0,
            'CRS': 'ProjectCrs',
            'EXPRESSION': '\"Input_Raster@1\" *  ( \"Input_Raster@1\" = 1  OR  \"Input_Raster@1\" = 2 ) + 3 *  ( \"Input_Raster@1\" >= 91 AND \"Input_Raster@1\" <= 93 ) + 4 *  ( \"Input_Raster@1\" = 7  OR  \"Input_Raster@1\" = 8 ) + 5 *  ( \"Input_Raster@1\" = 6  OR   \"Input_Raster@1\" = 6  ) ',
            'EXTENT': None,
            'LAYERS': parameters['InputRaster'],
            'OUTPUT': parameters['Output']
        }
        outputs['RasterCalculator'] = processing.run('qgis:rastercalculator', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Output'] = outputs['RasterCalculator']['OUTPUT']
        return results

    def name(self):
        return 'model'

    def displayName(self):
        return 'model'

    def group(self):
        return ''

    def groupId(self):
        return ''

    def createInstance(self):
        return Model()
