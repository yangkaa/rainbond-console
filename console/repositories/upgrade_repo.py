# coding: utf-8
import json

from console.models.main import AppUpgradeRecord
from console.models.main import ServiceUpgradeRecord
from console.models.main import UpgradeStatus


class UpgradeRepo(object):
    def get_app_not_upgrade_record(self, **kwargs):
        return AppUpgradeRecord.objects.get(**kwargs)

    def create_app_upgrade_record(self, **kwargs):
        return AppUpgradeRecord.objects.create(**kwargs)

    def create_service_upgrade_record(self, app_upgrade_record, service, event, update,
                                      status=UpgradeStatus.UPGRADING.value):
        """创建服务升级记录"""
        return ServiceUpgradeRecord.objects.create(
            app_upgrade_record=app_upgrade_record,
            service_id=service.service_id,
            service_cname=service.service_cname,
            event_id=event.event_id if event else '',
            update=json.dumps(update),
            status=status,
        )

    def change_app_record_status(self, app_record, status):
        """改变应用升级记录状态"""
        app_record.status = status
        app_record.save()

    def change_service_record_status(self, service_record, status):
        """改变服务升级记录状态"""
        service_record.status = status
        service_record.save()


upgrade_repo = UpgradeRepo()