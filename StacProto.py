from pathlib import Path
import pystac
from utils import search_items
catalog = pystac.Catalog(
    id='Field_Digital_Twin',
    description='Satellite and drone data for field digital twin.',
    stac_extensions=['https://stac-extensions.github.io/projection/v1.0.0/schema.json']
)

from shapely.geometry import Polygon, mapping
import rasterio as rio

def get_bbox_and_footprint(dataset):

    # create the bounding box it will depend if it comes from rasterio or rioxarray
    bounds = dataset.bounds

    if isinstance(bounds, rio.coords.BoundingBox):
        bbox = [bounds.left, bounds.bottom, bounds.right, bounds.top]
    else:
        bbox = [float(f) for f in bounds()]

    # create the footprint
    footprint = Polygon([
        [bbox[0], bbox[1]],
        [bbox[0], bbox[3]],
        [bbox[2], bbox[3]],
        [bbox[2], bbox[1]]
    ])

    return bbox, mapping(footprint)




import pandas as pd
from rasterio.warp import transform_bounds, transform_geom

# get a list of files
folder = Path('./digital_twin/field/Planet/') # For Cyverse digital twin directory
hspecs = list(folder.rglob('*.tif')) # Hyperspectral Data
#DroneRGBs = list(folder.rglob('../DroneRGB/*.png')) # Topview Drone RGB data
#Dronethermals = list(folder.rglob('../Dronethermal/*.png')) #Topview Drone thermal data

for hspec in hspecs:

    # open the mask with rasterio
    ds = rio.open(hspec)

    bbox, footprint = get_bbox_and_footprint(ds)

    # Project to WGS84 to obtain in geometric coordinates
    geo_bounds = transform_bounds(ds.crs, 'EPSG:4326', *bbox)
    geo_footprint = transform_geom(ds.crs, 'EPSG:4326', footprint)

    # properties
    idx = hspec.stem[:38] # "stems everything before 38th character in the file name. Here, it will act as an ID"
    date = pd.to_datetime(hspec.stem[11:26]) # "Extract and convert characters from the file name into date and time"
    tile = hspec.parts[1] # Sequence-like access to the to the components in the filesystem path.

    item = pystac.Item(
        id=idx,
        geometry=geo_footprint,
        bbox=geo_bounds,
        datetime=date,
        stac_extensions=['https://stac-extensions.github.io/projection/v1.0.0/schema.json'],
        properties=dict(
            tile=tile
        )
    )

    catalog.add_item(item)

print(len(list(catalog.get_items())))
catalog.describe()

from pystac.extensions.projection import AssetProjectionExtension

for hspec in hspecs:
    idx = hspec.stem[:38]
    item = catalog.get_item(idx)

    # as before, let's open the mask with rasterio and get bbox and footprint
    ds = rio.open(hspec)
    bbox, footprint = get_bbox_and_footprint(ds)

    item.add_asset(
        key='Hyperspectral',
        asset=pystac.Asset(
            href=hspec.as_posix(),
            media_type=pystac.MediaType.GEOTIFF
        )
    )

    # extend the asset with projection extension
    asset_ext = AssetProjectionExtension.ext(item.assets['Planet.com'])
    asset_ext.epsg = ds.crs.to_epsg()
    asset_ext.shape = ds.shape
    asset_ext.bbox = bbox
    asset_ext.geometry = footprint
    asset_ext.transform = [float(getattr(ds.transform, letter)) for letter in 'abcdef']

    idx = hspec.stem[:38]
    item = catalog.get_item(idx)

    # add the drone rgb data (Top View)
    RGB = hspec.with_name(idx + '_DroneRGB.png')
    assert RGB.exists()

    item.add_asset(
        key='droneRGB',
        asset=pystac.Asset(
            href=RGB.as_posix(),
            media_type=pystac.MediaType.PNG
        )
    )

    # add the Thermals

    Thermal = hspec.with_name(idx + '_DroneThermal.png')
    assert Thermal.exists()

    item.add_asset(
        key='DroneThermal',
        asset=pystac.Asset(
            href=Thermal.as_posix(),
            media_type=pystac.MediaType.PNG
        )
    )

catalog.normalize_hrefs('./stac_catalog')
catalog.save()


# TESTING
import json

cat = pystac.Catalog.from_file('./stac_catalog/catalog.json')
item = list(cat.get_items())[-1]

print(json.dumps(item.to_dict(), indent=4))
