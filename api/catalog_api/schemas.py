from pydantic import BaseModel, ConfigDict


class TextField(BaseModel):
    text: str


class PairedTextField(TextField):
    script: str


class Record(BaseModel):
    id: str
    title: list[PairedTextField]


class Response(BaseModel):
    detail: str


class Response404(Response):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "detail": "Record not found",
                }
            ]
        }
    )
