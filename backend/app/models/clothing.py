"""
SQLAlchemy ORM 모델 — 의류 (Clothing) 및 태그 (ClothTag)

plan.md 스키마를 기반으로 구현합니다.
"""
from datetime import datetime
from sqlalchemy import (
    BigInteger, String, Text, DateTime, ForeignKey, func
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Clothing(Base):
    """
    의류 아이템 테이블.
    이미지 URL, 카테고리, 파이프라인 처리 상태 등을 저장합니다.
    """
    __tablename__ = "clothes"

    cloth_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False, index=True)

    # 이미지 경로 (로컬 파일 시스템 경로 또는 URL)
    image_url: Mapped[str] = mapped_column(Text, nullable=False)           # 크롭 이미지
    original_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)  # 원본 이미지

    # 의류 기본 메타데이터 (단일 값)
    category: Mapped[str | None] = mapped_column(String(50), nullable=True)      # 상의, 하의, 아우터 등
    sub_category: Mapped[str | None] = mapped_column(String(50), nullable=True)  # 셔츠, 슬랙스 등
    pattern: Mapped[str | None] = mapped_column(String(50), nullable=True)       # 무지, 스트라이프 등

    # 파이프라인 처리 상태
    pipeline_status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="pending",   # pending | processing | done | failed
        server_default="pending",
    )
    pipeline_error: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    tags: Mapped[list["ClothTag"]] = relationship(
        "ClothTag",
        back_populates="clothing",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class ClothTag(Base):
    """
    의류 다중 태그 테이블.
    색상(color), 소재(material), 스타일(style), 계절(season) 등
    다중 값을 갖는 속성을 별도 행으로 저장합니다.

    tag_type 예시: 'color', 'material', 'style', 'season'
    tag_value 예시: 'Black', 'Cotton', 'Casual', 'Spring'
    """
    __tablename__ = "cloth_tags"

    tag_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    cloth_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("clothes.cloth_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    tag_type: Mapped[str] = mapped_column(String(50), nullable=False)    # 태그 종류
    tag_value: Mapped[str] = mapped_column(String(100), nullable=False)  # 태그 값

    # Relationships
    clothing: Mapped["Clothing"] = relationship("Clothing", back_populates="tags")
