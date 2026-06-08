"""
SQLAlchemy ORM 모델 — 코디 (Outfit) 및 코디-의류 매핑

추후 코디 추천 기능 개발 시 사용합니다. 현재는 스텁(Stub)입니다.
"""
from datetime import datetime
from sqlalchemy import BigInteger, String, Text, Integer, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Outfit(Base):
    """
    코디 조합 테이블.
    사용자가 저장하거나 시스템이 추천한 코디 세트를 저장합니다.
    """
    __tablename__ = "outfits"

    outfit_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False, index=True)
    name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    compatibility_score: Mapped[int | None] = mapped_column(Integer, nullable=True)  # VLM 평점 (0~100)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    outfit_items: Mapped[list["OutfitItem"]] = relationship(
        "OutfitItem",
        back_populates="outfit",
        cascade="all, delete-orphan",
    )


class OutfitItem(Base):
    """
    코디-의류 매핑 테이블 (N:M 인터섹션).
    """
    __tablename__ = "outfit_items"

    outfit_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("outfits.outfit_id", ondelete="CASCADE"),
        primary_key=True,
    )
    cloth_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("clothes.cloth_id", ondelete="CASCADE"),
        primary_key=True,
    )

    # Relationships
    outfit: Mapped["Outfit"] = relationship("Outfit", back_populates="outfit_items")
