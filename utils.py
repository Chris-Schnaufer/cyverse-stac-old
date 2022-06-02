def search_items(catalog, tiles, start_date, end_date, utc=True):

    # convert tiles to a list (if it is not)
    tiles = [tiles] if not isinstance(tiles, list) else tiles

    start_date = pd.to_datetime(start_date, utc=utc)
    end_date = pd.to_datetime(end_date, utc=utc)

    items = [item for item in catalog.get_items() if item.datetime > start_date and item.datetime < end_date and item.properties['tile'] in tiles]

    items = sorted(items, key=lambda x: x.datetime)

    return items


# Search items
# items = search_items(cat, ['22KDV', '22KEV', '22KFV', '22KGV'], '2018-01-01', '2018-02-01')
# len(items)