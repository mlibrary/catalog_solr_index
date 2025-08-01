import pymarc
from dataclasses import dataclass


class AlmaDigitalItem:
    def __init__(self, alma_digital_item_data: dict):
        self.data = alma_digital_item_data

    @property
    def url(self):
        return self.data.get("link")

    @property
    def delivery_description(self):
        return self.data.get("delivery_description")

    @property
    def label(self):
        return self.data.get("label")

    @property
    def public_note(self):
        return self.data.get("public_note")


class HathiTrustItem:
    def __init__(self, ht_item_data: dict):
        self.data = ht_item_data

    @property
    def id(self):
        return self.data.get("id")

    @property
    def url(self):
        return f"http://hdl.handle.net/2027/{self.id}"

    @property
    def description(self):
        return self.data.get("description")

    @property
    def source(self):
        return self.data.get("source")

    @property
    def status(self):
        return self.data.get("status")


class ElectronicItem:
    def __init__(self, electronic_item_data: dict):
        self.data = electronic_item_data

    @property
    def url(self):
        return self.data.get("link")

    @property
    def campuses(self):
        return self.data.get("campuses") or []

    @property
    def interface_name(self):
        return self.data.get("interface_name")

    @property
    def collection_name(self):
        return self.data.get("collection_name")

    @property
    def description(self):
        return self.data.get("description")

    @property
    def public_note(self):
        return self.data.get("public_note")

    @property
    def note(self):
        return self.data.get("note")

    @property
    def is_available(self):
        return (
            self.data.get("status") == "Available"
            or self.data.get("link_text") == "Available online"
        )


@dataclass(frozen=True)
class LibLoc:
    library: str
    location: str


@dataclass(frozen=True)
class PhysicalLocation:
    url: str
    text: str = None
    floor: str = None
    code: LibLoc = None
    temporary: bool = False


class PhysicalItem:
    def __init__(self, physical_item_data: dict, bib_id: str, record=None):
        self.data = physical_item_data
        self.bib_id = bib_id
        self.record = record

    @property
    def item_id(self):
        return self.data.get("item_id")

    @property
    def barcode(self):
        return self.data.get("barcode")

    @property
    def fulfillment_unit(self):
        return self.data.get("fulfillment_unit")

    @property
    def call_number(self):
        return self.data.get("callnumber")

    @property
    def process_type(self):
        return self.data.get("process_type")

    @property
    def item_policy(self):
        return self.data.get("item_policy")

    @property
    def description(self):
        return self.data.get("description")

    @property
    def inventory_number(self):
        return self.data.get("inventory_number")

    @property
    def material_type(self):
        return self.data.get("material_type")

    @property
    def reservable(self):
        return self.data.get("can_reserve")

    @property
    def url(self):
        if self.reservable:
            return "what"
            # send over the marc record to some classes that can parse the Reserve This item
        return f"https://search.lib.umich.edu/catalog/record/{self.bib_id}/get-this/{self.barcode}"

    @property
    def physical_location(self):
        return PhysicalLocation(
            url=self.data.get("info_link"),
            text=self.data.get("display_name"),
            code=LibLoc(
                library=self.data.get("library"), location=self.data.get("location")
            ),
            temporary=self.data.get("temp_location"),
        )


class PhysicalHolding:
    def __init__(self, physical_holding_data: list, bib_id: str, record: pymarc.Record):
        self.data = physical_holding_data
        self.bib_id = bib_id
        self.record = record

    @property
    def holding_id(self):
        return self.data.get("hol_mmsid")

    @property
    def call_number(self):
        return self.data.get("callnumber")

    @property
    def summary(self):
        return self.data.get("summary_holdings")

    @property
    def public_note(self):
        return self.data.get("public_note")

    @property
    def physical_location(self):
        return PhysicalLocation(
            url=self.data.get("info_link"),
            text=self.data.get("display_name"),
            floor=self.data.get("floor_location"),
            code=LibLoc(
                library=self.data.get("library"), location=self.data.get("location")
            ),
        )

    @property
    def items(self):
        return [
            PhysicalItem(item, bib_id=self.bib_id, record=self.record)
            for item in self.data.get("items", [])
        ]


class FindingAids:
    def __init__(self, items: list, physical_holding: dict):
        self.items_data = items
        self.physical_holding = physical_holding  # the holding with one item

    @property
    def physical_location(self):
        return PhysicalLocation(
            url=self.physical_holding.get("info_link"),
            text=self.physical_holding.get("display_name"),
            floor=self.physical_holding.get("floor_location"),
            code=LibLoc(
                library=self.physical_holding.get("library"),
                location=self.physical_holding.get("location"),
            ),
        )

    @property
    def items(self):
        return [
            FindingAidItem(
                finding_aid_item_data=item_data, physical_holding=self.physical_holding
            )
            for item_data in self.items_data
        ]


class FindingAidItem:
    def __init__(self, finding_aid_item_data: dict, physical_holding: dict):
        self.data = finding_aid_item_data
        self.physical_holding = physical_holding  # the holding with one item

    @property
    def url(self):
        return self.data.get("link")

    @property
    def description(self):
        return self.data.get("description")

    @property
    def call_number(self):
        items = self.physical_holding.get("items")
        item = items[0] if items else None
        return item.get("callnumber") if item else None


def kind_of_holding(holding_item: dict):
    match holding_item["library"]:
        case "ALMA_DIGITAL":
            return "alma_digital"
        case "HathiTrust Digital Library":
            return "hathi_trust"
        case "ELEC":
            if holding_item["finding_aid"]:
                return "finding_aid"
            else:
                return "electronic"
        case _:
            return "physical"


def physical_holdings(
    holdings_data: list, bib_id: str, record
) -> list[PhysicalHolding]:
    return [
        PhysicalHolding(holding_item, bib_id=bib_id, record=record)
        for holding_item in holdings_data
        if kind_of_holding(holding_item) == "physical"
    ]


def electronic_items(holdings_data: list) -> list[ElectronicItem]:
    return [
        ElectronicItem(holding_item)
        for holding_item in holdings_data
        if kind_of_holding(holding_item) == "electronic"
    ]


def finding_aids(holdings_data: list) -> list[FindingAidItem]:
    physical_holding = None
    for holding in holdings_data:
        if holding.get("record_has_finding_aid"):
            physical_holding = holding

    items = [
        holding_item
        for holding_item in holdings_data
        if kind_of_holding(holding_item) == "finding_aid"
    ]
    if items:
        return FindingAids(physical_holding=physical_holding, items=items)


def alma_digital_items(holdings_data: list) -> list[AlmaDigitalItem]:
    return [
        AlmaDigitalItem(holding_item)
        for holding_item in holdings_data
        if kind_of_holding(holding_item) == "alma_digital"
    ]


def hathi_trust_items(holdings_data: list) -> list[HathiTrustItem]:
    ht_holding = None
    for holding_item in holdings_data:
        if kind_of_holding(holding_item) == "hathi_trust":
            ht_holding = holding_item

    if ht_holding:
        return [HathiTrustItem(item) for item in ht_holding["items"]]
    else:
        return []


class Holdings:
    def __init__(self, holdings_data: list, bib_id: str, record: pymarc.Record):
        self.data = holdings_data
        self.bib_id = bib_id
        self.record = record

    @property
    def hathi_trust_items(self):
        return hathi_trust_items(self.data)

    @property
    def alma_digital_items(self):
        return alma_digital_items(self.data)

    @property
    def electronic_items(self):
        return electronic_items(self.data)

    @property
    def finding_aids(self):
        return finding_aids(self.data)

    @property
    def physical(self):
        return physical_holdings(self.data, self.bib_id, self.record)
