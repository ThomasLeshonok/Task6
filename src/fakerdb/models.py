from dataclasses import dataclass

@dataclass(frozen=True)
class Locale:
    code: str
    name: str

@dataclass(frozen=True)
class BatchRequest:
    locale: str
    seed: int
    batch: int
    batch_size: int
    about_sentences: int

@dataclass(frozen=True)
class TextRequest:
    locale: str
    seed: int
    paragraphs: int
    sentences: int

@dataclass(frozen=True)
class FakeUser:
    position: int
    full_name: str
    gender: str
    address: str
    latitude: float
    longitude: float
    height: str
    height_cm: float
    weight: str
    weight_kg: float
    eye_color: str
    hair_color: str
    blood_type: str
    phone: str
    email: str
    about: str
