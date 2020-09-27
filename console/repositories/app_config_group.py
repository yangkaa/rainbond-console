from console.models.main import ApplicationConfigGroup
from console.models.main import ConfigGroupService
from console.models.main import ConfigGroupItem
from console.repositories.base import BaseConnection


class ApplicationConfigGroupRepository(object):
    def create(self, **data):
        return ApplicationConfigGroup.objects.create(**data)

    def update(self, app_id, config_group_name, **data):
        ApplicationConfigGroup.objects.filter(app_id=app_id, config_group_name=config_group_name).update(**data)
        res = ApplicationConfigGroup.objects.get(app_id=app_id, config_group_name=config_group_name)
        return res

    def get_config_group_by_id(self, app_id, config_group_name):
        print(app_id, config_group_name)
        return ApplicationConfigGroup.objects.get(app_id=app_id, config_group_name=config_group_name)

    def list_config_groups_by_app_id(self, app_id, page=None, page_size=None):
        limit = ""
        if page is not None and page_size is not None:
            page = page if page > 0 else 1
            page = (page - 1) * page_size
            limit = "LIMIT {page}, {page_size}".format(page=page, page_size=page_size)
        where = """
                WHERE
                    app_id = "{app_id}"
                """.format(app_id=app_id)
        sql = """
                SELECT
                    *
                FROM
                    app_config_group
                {where}
                ORDER BY
                    create_time desc
                {limit}
                """.format(
            where=where, limit=limit)
        conn = BaseConnection()
        return conn.query(sql)

    def count_config_groups_by_app_id(self, app_id):
        return ApplicationConfigGroup.objects.filter(app_id=app_id).count()

    def delete(self, app_id, config_group_name):
        application = ApplicationConfigGroup.objects.get(app_id=app_id, config_group_name=config_group_name)
        row = ApplicationConfigGroup.objects.filter(app_id=application.ID).delete()
        return row > 0


class ApplicationConfigGroupServiceRepository(object):
    def create(self, **data):
        return ConfigGroupService.objects.create(**data)

    def list_config_group_services_by_id(self, app_id, config_group_name):
        return ConfigGroupService.objects.filter(app_id=app_id, config_group_name=config_group_name)

    def delete(self, app_id, config_group_name):
        return ConfigGroupService.objects.filter(app_id=app_id, config_group_name=config_group_name).delete()


class ApplicationConfigGroupItemRepository(object):
    def create(self, **data):
        return ConfigGroupItem.objects.create(**data)

    def update(self, app_id, config_group_name, item_key, **data):
        ConfigGroupItem.objects.filter(app_id=app_id, config_group_name=config_group_name, item_key=item_key).update(**data)
        res = ConfigGroupItem.objects.get(app_id=app_id, config_group_name=config_group_name, item_key=item_key)
        return res

    def list_config_group_items_by_id(self, app_id, config_group_name):
        return ConfigGroupItem.objects.filter(app_id=app_id, config_group_name=config_group_name)

    def delete(self, app_id, config_group_name):
        return ConfigGroupItem.objects.filter(app_id=app_id, config_group_name=config_group_name).delete()


app_config_group_repo = ApplicationConfigGroupRepository()
app_config_group_service_repo = ApplicationConfigGroupServiceRepository()
app_config_group_item_repo = ApplicationConfigGroupItemRepository()